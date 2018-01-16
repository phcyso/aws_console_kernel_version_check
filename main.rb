
require 'aws-sdk-ec2'
require 'base64'
require 'pry'

good_versions = [
  'Linux version 4.4.0-1048-aws',
  'Linux version 4.9.75-25.55.amzn1.x86_64',
  'Linux version 3.13.0-139-generic',
  'Linux version 3.10.0-693.11.6.el7.x86_64',
  'Linux version 4.4.0-108-generic',
  'Linux version 4.4.0.109-generic'
]

@good_instances = []
@bad_instances = []
@manual_instances = []

def check_manually(instance)
  @manual_instances << {instance: instance, message: "No console text, check manually."}
end

def getNameTag(instance)
  name_tag = instance.tags.select{|tag| tag.key == "Name"}.first
  name_tag == nil ? "" : name_tag.value
end

def print_good
  puts "\n##### Good Instances ##### "
  puts "ID,\t Name,\t Kernel String "
  @good_instances.each do |ins|
    instance = ins[:instance]
    print "#{instance.instance_id},\t#{getNameTag(instance)},\t#{ins[:kernel_version]}\n"
  end
end

def print_bad
  puts "\n##### Bad Instances ##### "
  puts "ID,\t Name,\t Kernel String "
  @bad_instances.each do |ins|
    instance = ins[:instance]
    print "#{instance.instance_id},\t#{getNameTag(instance)},\t#{ins[:full_version_string]}\n"
  end
end

def print_manual
  puts "\n##### Check these instances manually ##### "
  puts "ID: \t, Name "
  @manual_instances.each do |ins|
    instance = ins[:instance]
    print "#{instance.instance_id},\t#{getNameTag(instance)},\n"
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
