#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'open-uri'
require 'json'
require 'time'
require 'sinatra'

STATUS_PAGE = 'http://support.xbox.com/en-US/xbox-live-status'

STATUS = {
  'Limited' => 'unavailable',
  'up and running' => 'active'
}

@cache = nil

get '/' do
  content_type :json
  current_status
end

helpers do
  def update_status?
    @cache.nil? || DateTime.now.new_offset(0) >= (@cache[:last_updated_at] + 60*5)
  end

  def current_status
    update_status if update_status?

    @cache[:json]
  end

  def update_status
    statuses = []
    doc = Nokogiri::HTML(open(STATUS_PAGE))

    doc.css('ul.core li.service h3').each do |service|
      name      = service.children.first.content
      status    = STATUS[service.children.last.content]

      case status
      when "unavailable"
        platforms = []
        services  = []

        service.parent.css('ul.platforms li.platform').each do |p|
          platform = p.css('p').text
          icon     = "http://support.xbox.com" + p.css('div.icon img').first['src']
          platforms << {:name => platform, :icon => icon}
        end

        service.parent.css('ul.services li p').each do |s|
          services << {:description => s.text}
        end

        affected = {:platforms => platforms, :services => services}

        puts service.parent.css('p.heading.timestamp').text[0..-2]
        last_updated_at = DateTime.strptime(service.parent.css('p.heading.timestamp').text[0..-2],
          '%m/%d/%Y %k:%M:%S %p %Z')
        message = service.parent.css('div.details p').text

        details = {:last_updated_at => last_updated_at, :message => message}
      when "active"

      end

      service = {
        :name => name,
        :status => status,
        :affected => affected,
        :details => details
      }

      statuses << service
    end

    now = DateTime.now.new_offset(0)
    @cache = {:lasted_updated_at => now,
              :json => JSON.pretty_generate({
                :services => statuses,
                :last_updated_at => now
              })}
  end
end
