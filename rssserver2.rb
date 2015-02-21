#!/usr/bin/env ruby
# coding: utf-8
require 'cgi'
require 'open-uri'
require 'rss'
require 'kconv'

class Site
  def initialize(url:"", title:"")
    @url, @title, = url, title
  end
  attr_reader :url, :title

  def page_source
    @page_source ||= open(@url, &:read).toutf8
  end
  def output(formatter_klass)
    formatter_klass.new(self).format(parse)
  end
end

class SbcrTopics < Site
  def parse
    dates = page_source.scan(%r!(\d+)年 ?(\d+)月 ?(\d+)日<br />!)
    url_titles = page_source.scan(%r!^<a href="(.+?)">(.+?)</a><br />!)  
    url_titles.zip(dates).map{ |(aurl, atitle),ymd|[CGI.unescapeHTML(aurl),CGI.unescapeHTML(atitle),Time.local(*ymd)]}
  end
end

class Formatter
  def initialize(site)
    @url = site.url
    @title = site.title
  end
  attr_reader :url, :title
end

class TextFormatter < Formatter
  def format(url_title_time_ary) # →TextFormatter
    s = "Title: #{title}\nURL: #{url}\n\n"
    url_title_time_ary.each do |aurl, atitle, atime|
      s << "* (#{atime})#{atitle}\n"
      s << "     #{aurl}\n"
    end
    s
  end
end

class RSSFormatter < Formatter
  def format(url_title_time_ary) # →RSSFormatter
    RSS::Maker.make("2.0") do |maker|
      maker.channel.updated = Time.now.to_s
      maker.channel.link = url
      maker.channel.title = title
      maker.channel.description = title
      url_title_time_ary.each do |aurl, atitle, atime|
        maker.items.new_item do |item| 
          item.link = aurl
          item.title = atitle
          item.updated = atime
          item.description = atitle
        end
      end
    end
  end
end

parsed = parse(open("http://crawler.sbcr.jp/samplepage.html", "r:UTF-8", &:read))

formatter = case ARGV.first
            when "rss-output"
              :format_rss
            when "text-output"
              :format_text
            end

puts __send__(formatter,"WWW.SBCR.JP トピックス","http://crawler.sbcr.jp/samplepage.html", parsed)


