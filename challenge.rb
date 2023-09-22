# frozen_string_literal: true

require 'json'

# Helper method to read and parse JSON files with error handling
# @param [String] filename - The name of the JSON file to read.
# @return [Array] - An array containing the parsed JSON data.
def read_json_file(filename)
  JSON.parse(File.read(filename))
rescue JSON::ParserError => e
  puts "Can't parse JSON in #{filename}: #{e.message}"
  exit 1
rescue Errno::ENOENT => e
  puts "JSON file #{filename} cannot be opened: #{e.message}"
  exit 1
end

# Read JSON files
users = read_json_file('users.json')
companies = read_json_file('companies.json')

# Create a hash to store users grouped by company ID
users_by_company = users.group_by { |user| user['company_id'] }

# Create a hash to store the total top-up amount for each company
total_top_ups = Hash.new(0)

# Generate the output for each company
output = ''

companies.each do |company|
  company_id = company['id']
  company_name = company['name']
  email_status = company['email_status'] ? 'Email sent' : 'Email not sent'

  output += "Company Id: #{company_id}\n"
  output += "Company Name: #{company_name}\n"
  output += "Users Emailed:\n"

  users_emailed = users_by_company[company_id] || []

  users_emailed.each do |user|
    user_tokens = user['tokens'] + company['top_up']
    output += "  #{user['last_name']}, #{user['first_name']}, #{user['email']} - #{email_status}\n"
    output += "    Previous Token Balance, #{user['tokens']}\n"
    output += "    New Token Balance, #{user_tokens}\n"
  end

  output += "Users Not Emailed:\n"

  users_not_emailed = users_by_company[company_id] || []

  users_not_emailed.each do |user|
    user_tokens = user['tokens'] + company['top_up']
    output += "  #{user['last_name']}, #{user['first_name']}, #{user['email']}\n"
    output += "    Previous Token Balance, #{user['tokens']}\n"
    output += "    New Token Balance, #{user_tokens}\n"
    total_top_ups[company_id] += company['top_up']
  end

  output += "Total amount of top ups for #{company_name}: #{total_top_ups[company_id]}\n\n"
end

# Write the output to output.txt
begin
  File.open('output.txt', 'w') { |file| file.write(output) }
  puts 'Result written to output.txt'
rescue IOError => e
  puts "Error writing to output.txt: #{e.message}"
  exit 1
end
