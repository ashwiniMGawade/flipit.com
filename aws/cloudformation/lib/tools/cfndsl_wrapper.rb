class AWSTemplate
  def initialize(description=nil)
    @description = description
    @resources = {}
    @outputs = {}
  end

  def resource(id, type=nil, &block)
    if type
      raise "Resource name collision '#{id}'." if @resources.has_key? id.to_s
      @resources[id.to_s] = AWSResource.new type, id
    end

    @resources[id.to_s].body &block if block_given?

    return @resources[id.to_s]
  end

  def output(id, &block)
    raise "Output name collision '#{id}'." if @outputs.has_key? id.to_s
    @outputs[id.to_s] = AWSOutput.new id
    @outputs[id.to_s].body &block if block_given?
    return @outputs[id.to_s]
  end

  def render(ctxt=nil)
    description = nil
    resources = @resources
    outputs = @outputs

    if ctxt
      ctxt.instance_eval do
        resources.each_pair do |id, resource|
          resource.render(self)
        end
      end
    else
      CloudFormation {
        Description description if description

        resources.each_pair do |id, resource|
          resource.render(self)
        end

        outputs.each_pair do |id, output|
          output.render(self)
        end
      }
    end
  end
end

module CfnDsl
  module Functions
    alias :CfnDsl_Ref :Ref
    remove_method :Ref

    def Ref(ref)
      if ref.is_a? AWSResource
        CfnDsl_Ref(ref.id)
      elsif ref.is_a? Enumerable
        ref.map {|r| Ref(r)}
      else
        CfnDsl_Ref(ref)
      end
    end

    alias :CfnDsl_FnGetAtt :FnGetAtt
    remove_method :FnGetAtt

    def FnGetAtt(ref, att)
      if ref.is_a? AWSResource
        CfnDsl_FnGetAtt(ref.id, att)
      else
        CfnDsl_FnGetAtt(ref, att)
      end
    end
  end

  class ResourceDefinition
    alias :CfnDsl_DependsOn :DependsOn
    remove_method :DependsOn

    def DependsOn(ref)
      if ref.is_a? AWSResource
        CfnDsl_DependsOn(ref.id)
      elsif ref.is_a? Enumerable
        CfnDsl_DependsOn(ref.map { |r| r.is_a?(AWSResource) ? r.id : r })
      else
        CfnDsl_DependsOn(ref)
      end
    end
  end
end

class AWSResource
  attr_reader :id, :type

  def initialize(type, id)
    raise "Resource name '#{id}' is non alphanumeric." unless id =~ /^[a-zA-Z0-9]+$/

    @type = type
    @id = id
    @blocks = []
    @values = {}
  end

  def set(key, value)
    @values[key.to_s] = value
  end

  def get(key)
    @values[key.to_s]
  end

  def body(&block)
    @blocks << block if block_given?
  end

  def render(ctxt)
    type = @type
    id = @id
    blocks = @blocks

    ctxt.instance_eval do
      Resource(id) {
        Type type

        blocks.each do |block|
          instance_eval &block
        end
      }
    end
  end

  def cidr
    if get(:cidr).present?
      subnet(get(:cidr))
    else
      raise 'No CIDR present'
    end
  end

  def ip(n)
    if get(:cidr).present?
      ip(get(:cidr), n)
    else
      raise 'No CIDR present'
    end
  end
end


class AWSOutput < AWSResource
  def initialize(id)
    raise "Output name '#{id}' is non alphanumeric." unless id =~ /^[a-zA-Z0-9]+$/
    super(nil, id)
  end

  def render(ctxt)
    id = @id
    blocks = @blocks

    ctxt.instance_eval do
      Output(id) {
        blocks.each do |block|
          instance_eval &block
        end
      }
    end
  end
end
