require 'yaml'

DEFAULT_SCHEDULE_FILE = ENV['SCHEDULE_FILE']

def schedule_autoscaling_actions(template, schedule_file = nil)
  cnf_file =  schedule_file || DEFAULT_SCHEDULE_FILE
  config = YAML.load_file(cnf_file)

  if ENV['CF_Hibernate'] != true
    config[:schedule][:auto_scaling_groups].each do |asg, actions|
      template.resource( asg, 'AWS::AutoScaling::AutoScalingGroup') {

      }
      actions.each do |action|
        scheduled_action(template, asg, action)
      end
    end
  end
rescue Errno::ENOENT => e
  $stderr.puts "\nSchedule configuration file '#{cnf_file}' not found.
  \rNo autoscaling actions scheduled...\n\n"
end


def scheduled_action(template, asg, attributes)
  name = attributes.delete(:name)
  template.resource( name, 'AWS::AutoScaling::ScheduledAction') {
    if asg.include? "Varnish"
      Condition :EnableVarnishServer
    elsif asg.include? "Web"
      Condition :EnableWebServer
    end
    Property :AutoScalingGroupName, Ref(asg)
    attributes.each do |key, value|
      Property key.to_s.camelize.to_sym, value
    end
  }

end
