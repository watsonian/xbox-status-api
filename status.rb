#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'open-uri'
require 'json'
require 'time'
require 'sinatra'

class XboxStatusApi < Sinatra::Base
  configure do
    set :status_page, 'http://support.xbox.com/en-US/xbox-live-status'

    STATUS = {
      'Limited' => 'unavailable',
      'up and running' => 'active'
    }
  end

  get '/' do
    content_type :json
    current_status
  end

  helpers do
    def update_status?
      @cache.nil? || ttl_reached?
    end

    def ttl_reached?
      @cache && (DateTime.now.new_offset(0) >= (@cache[:metadata][:last_updated_at] + ttl))
    end

    def ttl
      Rational(5, 1440) # 5 minutes
    end

    def current_status
      update_status if update_status?

      @cache[:json]
    end

    def update_status
      @cache ||= {}
      statuses = []
      services_unavailable = false
      doc = Nokogiri::HTML(open(settings.status_page))

      doc.css('ul.core li.service h3').each do |service|
        name      = service.children.first.content
        status    = STATUS[service.children.last.content]

        case status
        when "unavailable"
          services_unavailable = true
          platforms = []
          services  = []

          service.parent.css('ul.platforms li.platform').each do |p|
            platform  = p.css('p').text
            icon      = "http://support.xbox.com" + p.css('div.icon img').first['src']
            platforms << {:name => platform, :icon => icon}
          end

          service.parent.css('ul.services li p').each do |s|
            services << {:description => s.text}
          end

          affected = {:platforms => platforms, :services => services}

          timestamp = service.parent.css('p.heading.timestamp').text[0..-2]
          last_updated_at = DateTime.strptime(timestamp, '%m/%d/%Y %k:%M:%S %p %Z')
          message = service.parent.css('div.details p').text

          details = {:last_updated_at => last_updated_at, :message => message}
        end

        service = {
          :name => name,
          :status => status,
          :affected => affected,
          :details => details
        }

        statuses << service
      end

      if services_unavailable
        new_most_recent_update = statuses.select{|s| s[:details] && s[:details][:last_updated_at]}.max
        @cache[:most_recent_update] ||= new_most_recent_update
        update_since_last_check = (new_most_recent_update != @cache[:most_recent_update])
        @cache[:most_recent_update] = new_most_recent_update
      end

      now = DateTime.now.new_offset(0)
      @cache = {
                :json => JSON.pretty_generate({
                  :services => statuses,
                  :metadata => {
                    :last_updated_at => now,
                    :services_unavailable => services_unavailable,
                    :service_update_since_last_check => update_since_last_check
                  }
                })}
    end
  end
end
