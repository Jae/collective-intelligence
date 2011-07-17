require 'httparty'
require 'httparty_icebox'
require 'date'
require 'digest/md5'
module Deliruby
    #Abstract representation of a delicious bookmark item
    class DeliciousBookmark
        #The bookmarked url
        attr_accessor :url
        #The tags applied to it in this instance
        attr_accessor :tags
        #The title of this bookmark
        attr_accessor :title
        #The date when the bookmark was made
        attr_accessor :published_on
        #Who bookmarked it
        attr_accessor :creator

        def initialize(url, title="", published_on=nil, creator="", tags=[])
            @url = url 
            @tags = tags || []
            @title = title || ""
            @published_on = published_on ? DateTime.strptime(published_on, "%a, %d %b %Y %H:%M:%S %Z") : nil
            @creator = creator || ""
        end
        
        #convert this instance into a hash, based on 
        #{this snippet}[http://pullmonkey.com/2008/01/06/convert-a-ruby-hash-into-a-class-object/comment-page-1/]
        def to_hash
            hsh = {}
            self.instance_variables.each do |var| 
                hsh[var.gsub("@","")] = self.instance_variable_get(var)
            end
        end
    end
    #Provides instance methods to access the public feeds of delicious.com, returning an array of Bookmark instances 
    class Bookmarks 
        include HTTParty
        format :xml
        base_uri "http://feeds.delicious.com/v2/xml"
        include HTTParty::Icebox
        #cache :store => 'memory', :timeout => 300
        cache :store => 'file', :timeout => 300, :location => '/tmp/'
        
        #Base method for all the calls to the delicious api
        #Params:
        #+url+:: the sub-url to access
        def self.get_feed(url="/") 
            res = get(url)
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            bookmarks = []
            return [] unless res['rss']['channel'].has_key?('item')
            res['rss']['channel']['item'].each do |item|
                bookmarks.push DeliciousBookmark.new(item['link'], item['title'], item['pubDate'], item['dc:creator'],
                                                     item['category']) rescue next
            end
            return bookmarks
        end
        
        #Get the recent bookmarks on delicious
        def self.recent
            return self.get_feed('/recent')
        end
        
        #Get the recent bookmarks tagged with a combination of tags
        #Params:
        #+tags+:: an Array of tags; notice that the search is for bookmarks that include them all, not just a subset
        def self.by_tags(tags=[])        
            return self.get_feed("/tag/#{tags.join('+')}")
        end
        
        #Get the most recent popular bookmarks (optionally) by tag
        #Params:
        #+tag+:: the tag to get popular bookmarks for; if not provided, just gets the globally popular bookmarks
        def self.popular(tag="")
            return self.get_feed("/popular#{"/"+tag if tag}")
        end
        
        #Get the recent bookmarks of a user, by tags
        #Params:
        #+user+:: the delicious username of the queried user
        #+tags+:: an Array of tags, if not provided, just gets the recent bookmarks of the user
        def self.for_user(user, tags=[])
            return self.get_feed("/#{user}/#{tags.join('+')}")
        end

        #Get the recent bookmarks of a user's subscriptions
        #Params:
        #+user+:: the delicious username of the user
        def self.subscripted(user)
            return self.get_feed("/subscriptions/#{user}")
        end

        #Get the recent bookmarks of a user's network, by tags
        #Params:
        #+user+:: the delicious username
        #+tags+:: an optional array of tags to filter by
        def self.network(user, tags=[])
            return self.get_feed("/network/#{user}/#{tags.join('+')}")
        end

        #Get the recent bookmarks for a specific url
        #Params:
        #+url+:: the url for which to get recent bookmarks
        def self.for_url(url)
            return self.get_feed("/url/#{Digest::MD5.hexdigest(url)}")
        end
        class << self
            alias :hotlist :get_feed
            alias :tagged :by_tags
            alias :for :for_user
            alias :for_network :network
            alias :for_subscriptions :subscripted
        end
    end #of class Bookmarks
    
    #access the public information that's not necesarily bookmarks
    #because the information varies, it returns hashes or arrays of hashes instead of a class instance
    class PublicInfo
        include HTTParty
        format :xml
        base_uri "http://feeds.delicious.com/v2/xml"
        include HTTParty::Icebox
        #cache :store => 'memory', :timeout => 300
        cache :store => 'file', :timeout => 300, :location => '/tmp/'

        #Get a the site alerts
        #Params
        #+url+:: the url to retrieve
        def self.alerts
            res = get("/alerts")
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            return [] unless res['rss']['channel'].has_key?('item')
            alerts = []
            res['rss']['channel']['item'].each do |item|
                alerts.push item rescue next
            end
            return alerts
        end
        
        #Get public info for a user: the number of bookmarks, network members and network fans
        #Params
        #+user+:: the user
        def self.user_info(user)
            res = get("/userinfo/#{user}")
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            return [] unless res['rss']['channel'].has_key?('item')
            info = {}
            res['rss']['channel']['item'].each do |item|
                info[item['title']] = item['description'] rescue next
            end
            return info
        end
        
        #Get the top public tags of a user and how many items are bookmarked with them
        #and also get the related tags if a filtering array of tags is provided
        #Params:
        #+user+:: the user to peruse
        #
        def self.tags(user, tags=[])
            res = get("/tags/#{user}/#{tags.join('+')}")
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            return [] unless res['rss']['channel'].has_key?('item')
            info = []
            res['rss']['channel']['item'].each do |item|
                info.push({item['title']=>item['description']}) rescue next
            end
            return info
        end
        
        #Get a list of the network members for a user
        #Params:
        #+user+:: the user to peruse
        def self.network(user)
            res = get("/networkmembers/#{user}")
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            return [] unless res['rss']['channel'].has_key?('item')
            members = []
            res['rss']['channel']['item'].each do |item|
                members.push({:user => item['title'], :profile=>item['link']}) rescue next
            end
            return members
        end

        #Get a list of the network fans for a user
        #Params:
        #+user+:: the user to peruse
        def self.network_fans(user)
            res = get("/networkfans/#{user}")
            raise "Communication error with delicious server: #{res.response['status']}" if res.response['status'] =~ /^[45]/
            return [] unless res['rss']['channel'].has_key?('item')
            members = []
            res['rss']['channel']['item'].each do |item|
                members.push({:user => item['title'], :profile=>item['link']}) rescue next
            end
            return members
        end
        
        #Return summary information for a given url
        def self.url(url)
            #for some reason, the cache screws this one up
            get_without_caching("/urlinfo/#{Digest::MD5.hexdigest(url)}",:format => :json, 
                            :base_uri => self.default_options[:base_uri].gsub('xml', 'json')).parsed_response[0]
        end

        class << self   
            alias :for_user :user_info
            alias :userinfo :user_info
            alias :tags_for_user :tags
            alias :tags_for :tags
            alias :network_for :network
            alias :network_for_user :network
            alias :network_fans_for :network_fans
            alias :network_fans_for_user :network_fans
            alias :for_url :url
            alias :urlinfo :url
            alias :url_info :url
        end
    end
end
