## aws_console_kernel_version_check

This script uses the aws console logs to try identify what kernel version a server is using to check if it is patched for spectre/meltdown

## Requirements

* Ruby 2.5.x
* aws-vault set up or AWS_... env variables set.

## Usage

`aws-vault exec --assume-role-ttl=60m <role>`
`bundle`
`bundle exec ruby main.rb`


https://github.com/phcyso/aws_console_kernel_version_check
