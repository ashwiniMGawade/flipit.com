require_relative 'tools/env'

template = AWSTemplate.new \
  "scheduled-actions"

# Add scheduled actions to template
schedule_autoscaling_actions(template)

#_Render_the_Template__________________________________________________________#
template.render
