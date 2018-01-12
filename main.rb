
require 'aws-sdk-ec2'
require 'base64'
require 'pry'

good_versions = [
  'Linux version 4.4.0-1048-aws',
  'Linux version 3.13.0-139-generic'
]

@good_instances = []
@bad_instances = []
@manual_instances = []

def check_manually(instance)
  @manual_instances << {instance: instance, message: "No console text, check manually."}
end

def print_good
    puts "##### Good Instances ##### "
  @good_instances.each do |ins|
    instance = ins[:instance]
    name_tag = instance.tags.select{|tag| tag.key == "Name"}.first
    name_value = name_tag == nil ? "" : name_tag.value
    print "id: #{instance.instance_id},\t Name: #{name_value},\t\t\t\t\t Kernel version: #{ins[:kernel_version]}\n"
  end
end

def print_bad
  puts "##### Bad Instances ##### "
  @bad_instances.each do |ins|
    instance = ins[:instance]
    name_tag = instance.tags.select{|tag| tag.key == "Name"}.first
    name_value = name_tag == nil ? "" : name_tag.value
    print "id: #{instance.instance_id},\t Name: #{name_value},\nRaw version string: #{ins[:full_version_string]}\n\n"
  end
end

def print_manual
  puts "##### Check these instances manually ##### "
  @manual_instances.each do |ins|
    instance = ins[:instance]
    name_tag = instance.tags.select{|tag| tag.key == "Name"}.first
    name_value = name_tag == nil ? "" : name_tag.value
    print "id: #{instance.instance_id}, Name: #{name_value}\n"
  end
end

ec2 = Aws::EC2::Resource.new(region:'us-west-2')
ec2.instances.each do |instance|

  next unless instance.state.name == "running"

  rawConsoleText = instance.console_output.output
  if rawConsoleText == nil
    check_manually instance
    next
  end

  decodedConsoleText = Base64.decode64(rawConsoleText)
  lastVersionString = decodedConsoleText.scan(/Linux version.*$/).last
  if lastVersionString == nil
    check_manually instance
    next
  end

  found_good = false
  good_versions.each do |vers|
    if lastVersionString.scan(/#{vers}/).any?
      @good_instances << {instance: instance, kernel_version: vers, full_version_string: lastVersionString}
      found_good = true
    end
  end

  if ! found_good
    @bad_instances << {instance: instance, full_version_string: lastVersionString}
  end
end

print_good
print_bad
print_manual
