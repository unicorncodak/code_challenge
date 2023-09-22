# frozen_string_literal: true

require 'json'

# Helper class to read and parse JSON files with error handling
class JSONReader
  # Reads and parses a JSON file.
  #
  # @param [String] filename - The name of the JSON file to read.
  # @return [Array] - An array containing the parsed JSON data.
  # @raise [RuntimeError] If there is an error reading or parsing the JSON file.
  def self.read(filename)
    JSON.parse(File.read(filename))
  rescue JSON::ParserError, Errno::ENOENT => e
    raise "Error reading JSON file #{filename}: #{e.message}"
  end
end

# Business logic class for managing users
class UserManager
  attr_reader :users

  # Initializes the UserManager with user data.
  #
  # @param [Array] users - An array containing user data.
  def initialize(users)
    @users = users
  end

  # Calculates token balances for users based on company data.
  #
  # @param [Array] companies - An array of company data.
  def calculate_token_balances(companies)
    users.each do |user|
      company = companies.find { |c| c['id'] == user['company_id'] }
      user['tokens'] += company['top_up'] if company
    end
  end

  # Filters and returns active users based on company data.
  #
  # @param [Array] companies - An array of company data.
  # @return [Array] - An array of active user data.
  def filter_active_users(companies)
    users.select do |user|
      company = companies.find { |c| c['id'] == user['company_id'] }
      company && user['active_status']
    end
  end
end

# Business logic class for managing companies
class CompanyManager
  attr_reader :companies

  # Initializes the CompanyManager with company data.
  #
  # @param [Array] companies - An array containing company data.
  def initialize(companies)
    @companies = companies
  end

  # Sorts companies based on company ID.
  #
  # @return [Array] - An array of sorted company data.
  def sort_companies
    companies.sort_by { |company| company['id'] }
  end

  # Calculates the total top-up amount for each company based on user data.
  #
  # @param [Array] users - An array of user data.
  # @return [Hash] - A hash mapping company IDs to total top-up amounts.
  def total_top_ups(users)
    top_ups = Hash.new(0)
    users.each do |user|
      company = companies.find { |c| c['id'] == user['company_id'] }
      top_ups[company['id']] += company['top_up'] if company
    end
    top_ups
  end
end

# Generate the output header for a company.
#
# @param [Hash] company - The company data.
# @return [String] - The formatted header.
def generate_company_header(company)
  header = "Company Id: #{company['id']}\n"
  header += "Company Name: #{company['name']}\n"
  header += "Users Emailed:\n"
  header
end

# Generate the output for a user who has been emailed.
#
# @param [Hash] user - The user data.
# @param [Hash] company - The company data.
# @return [String] - The formatted output for the emailed user.
def generate_emailed_user(user, company)
  output = "#{user['last_name']}, #{user['first_name']}, #{user['email']} - Email sent\n"
  output += "  Previous Token Balance: #{user['tokens'] - company['top_up']}\n"
  output += "  New Token Balance: #{user['tokens']}\n"
  output
end

# Generate the output for a user who has not been emailed.
#
# @param [Hash] user - The user data.
# @param [Hash] company - The company data.
# @return [String] - The formatted output for the user not emailed.
def generate_not_emailed_user(user, company)
  output = "#{user['last_name']}, #{user['first_name']}, #{user['email']} - Email not sent\n"
  output += "  Previous Token Balance: #{user['tokens'] - company['top_up']}\n"
  output += "  New Token Balance: #{user['tokens']}\n"
  output
end

# Generate the total top-up amount for a company.
#
# @param [Hash] total_top_up - The total top-up data.
# @return [String] - The formatted total top-up amount.
def generate_total_top_up(total_top_up)
  "Total amount of top ups for #{total_top_up[:company_name]}: #{total_top_up[:amount]}\n\n"
end

# Generate the output for a company, including emailed and not emailed users.
#
# @param [Hash] company - The company data.
# @param [Array] emailed_users - An array of emailed user data.
# @param [Array] not_emailed_users - An array of users not emailed.
# @param [Hash] total_top_up - The total top-up data.
# @return [String] - The formatted output for the company.
def generate_company_output(company, emailed_users, not_emailed_users, total_top_up)
  output = generate_company_header(company)
  output += emailed_users.map { |user| generate_emailed_user(user, company) }.join
  output += "Users Not Emailed:\n"
  output += not_emailed_users.map { |user| generate_not_emailed_user(user, company) }.join
  output += generate_total_top_up(total_top_up)
  output
end

# Generate the output for all companies.
#
# @param [Array] users - An array of user data.
# @param [Array] companies - An array of company data.
# @param [Hash] total_top_ups - A hash mapping company IDs to total top-up amounts.
# @return [String] - The formatted output for all companies.
def generate_output(users, companies, total_top_ups)
  output = ''
  ordered_companies = companies.sort_by { |company| company['id'] }

  ordered_companies.each do |company|
    emailed_users = users.select { |user| user['company_id'] == company['id'] && company['email_status'] }
    
    not_emailed_users = users.select { |user| user['company_id'] == company['id'] && !company['email_status'] }
    total_top_up = { company_name: company['name'], amount: total_top_ups[company['id']] }

    output += generate_company_output(company, emailed_users, not_emailed_users, total_top_up)
  end

  output
end

# Main program logic
def main
  # Load user and company data from JSON files
  users = JSONReader.read('users.json')
  companies = JSONReader.read('companies.json')

  # Create user and company managers
  user_manager = UserManager.new(users)
  company_manager = CompanyManager.new(companies)

  # Calculate token balances for users
  user_manager.calculate_token_balances(companies)

  # Filter active users
  active_users = user_manager.filter_active_users(companies)

  # Calculate total top-up amounts for companies
  total_top_ups = company_manager.total_top_ups(users)

  # Generate and write output to a file
  output = generate_output(active_users, companies, total_top_ups)
  File.open('output.txt', 'w') { |file| file.write(output) }
  puts 'Result written to output.txt'
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end

# Run the program
main
