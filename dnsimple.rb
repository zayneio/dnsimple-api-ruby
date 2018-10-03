require 'net/http'
require 'uri'
require 'json'

# user_token  = ENV['user_token']
# user_email = ENV['user_email']
# account_token = ENV['account_token']
# sandbox_token = ENV['sandbox_token']
# v1_token = ENV['v1_token']
# account_id = ENV['account_id']

class DomainChecker
  attr_accessor :v1_token, :user_email, :user_token, :account_id

  def initialize(v1_token, user_token, user_email, account_id)
    @v1_token = v1_token
    @user_token = user_token
    @user_email = user_email
    @account_id = account_id
  end
	
  def ask_user 
    puts 'enter a domain you want to look up:'
    input = gets.chomp
    puts 'checking...'
    self.domain_lookup(input)
  end

  def domain_lookup(input)
    uri = URI.parse("https://api.dnsimple.com/v1/domains/#{input}/check")

    request = Net::HTTP::Get.new(uri)
    request["X-Dnsimple-Token"] = "#{@user_email}:#{@v1_token}"
    request["Accept"] = "application/json"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }

    parsed_response = JSON.parse(response.body)
		
    if parsed_response['available']
      puts ' '
      p 'domain status: AVAILABLE'
      puts ' '
    else 
      puts ' '
      p 'domain status: NOT AVAILABLE'
      puts ' '
    end
		
    puts 'what would you like to do?'
    puts '1) enter "buy" to buy ' + input + ' for ' + parsed_response['currency_symbol'] + parsed_response['price']
    puts '2) enter "search" to search for another domain'
    puts '3) enter "exit" to leave'
		
    answer = gets.chomp.strip
    case answer
    when 'buy'
      self.register_domain(input)
    when 'search'
      self.ask_user
    else 
      p 'okay bye!'
    end
  end

  def register_domain(domain_name)
    list_contacts = self.list_accounts
    contacts = JSON.parse(list_contacts.body)
    if !contacts["data"].nil?
      puts 'select the contact you would like to use to register this domain'
      contacts["data"].each do |c|
        puts "-Please enter '" + c["id"].to_s + "' to choose " + c["first_name"] + " " + c["last_name"] + ' as the primary contact for this domain'
      end
      contact_id = gets.chomp.strip
    else
      puts 'no contacts created. Would you like to create one?'
      answer = gets.chomp.strip 
      if answer == 'yes'
        self.create_account_contact
        self.register_domain(domain_name)
      else
        return
      end
    end

    if !contact_id
      return
    end
    
    uri = URI.parse("https://api.dnsimple.com/v2/#{@account_id}/registrar/domains/#{domain_name}/registrations")
		
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{@user_token}"
    request["Accept"] = "application/json"
    request.body = {
      registrant_id: contact_id,
      whois_privacy: true
    }.to_json

    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
    # response.body
  end

  def list_accounts
    uri = URI.parse("https://api.dnsimple.com/v2/#{@account_id}/contacts")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@user_token}"
    request["Accept"] = "application/json"

    req_options = {
      use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http|  http.request(request) }
    # response.body
  end

  def create_account_contact
    uri = URI.parse("https://api.dnsimple.com/v2/#{@account_id}/contacts")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{@user_token}"
    request["Accept"] = "application/json"
    request.body = {
      first_name: 'Mcfirstname',
      last_name: 'Mclastname',
      address1: '1 Broadway',
      city: 'New York',
      state_province: 'NY',
      postal_code: '10019',
      country: 'USA',
      email: 'hello@example.com',
      phone: '+15555555555',
      fax: '+15555555555'
    }.to_json

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end
end


dnsimple = DomainChecker.new(v1_token, account_token, user_email, account_id)

dnsimple.ask_user