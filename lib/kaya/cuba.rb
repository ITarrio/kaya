require "cuba"

include Mote::Helpers

Cuba.define do

  $suites_counter = 0

  request = Kaya::Support::Request.new(req)

  $K_LOG.debug "REQUEST '#{request.request}" if $K_LOG

  begin


# ========================================================================
# COMMON INIT
#
#
    Kaya::Support::Configuration.get

    Kaya::Database::MongoConnector.new Kaya::Support::Configuration.db_connection_data

    $K_LOG.debug "HOSTNAME:#{HOSTNAME = Kaya::Support::Configuration.hostname}"


    on post do

      on "#{HOSTNAME}/kaya/delete-custom-param" do

        on true do

          data = req.params.dup

          data["_id"] = data["_id"].to_i

          response = Kaya::API::CustomParams.set data # Creates or update

          path = "/#{HOSTNAME}/kaya/custom/params"
          path += "?msg=#{response[:message]}" if response[:message]

          res.redirect path
        end

      end

      # TO EDIT OR CREATE CUSTOM PARAM
      on "#{HOSTNAME}/kaya/custom-param" do

        on true do

          data = req.params.dup

          $K_LOG.debug "data is => #{data}"

          response = Kaya::API::CustomParams.set data # Creates or update

          path = "/#{HOSTNAME}/kaya/custom/params"

          # Si success es true
          $K_LOG.debug "#{response}"

          unless response[:success]

            path += "/#{data['_id']}" if data["_id"]
            path += "/#{data['action']}"
          end
          path += "?msg=#{response[:message]}"

          path += "&name=#{data['name']}&action=#{data['action']}&type=#{data['type']}&value=#{data['value']}&options=#{data['options']}&required=data['required']&clean=false" unless response[:success]

          res.redirect path

        end

      end

    end




    on get do

# ========================================================================
# HELP
#
#
      on "#{HOSTNAME}/kaya/help/:page" do |page|
        args ={page:page}
        template = Mote.parse(File.read("#{Kaya::View.path}/help.mote"),self, [:args])
        res.write template.call(:args => args)
      end

      on "#{HOSTNAME}/kaya/help" do
        res.redirect "/#{HOSTNAME}/kaya/help/main"
      end


# ========================================================================
# VIEW ROUTES
#
#
#
      on "#{HOSTNAME}/kaya/results/log/:result_id" do |result_id|
        result = Kaya::Results::Result.get(result_id)
        res.redirect "/#{HOSTNAME}/kaya/404/There%20is%20no%20result%20for%20id=#{result_id}" if result.nil?
        result.mark_as_saw! if (result.finished? or result.stopped?)
        template = Mote.parse(File.read("#{Kaya::View.path}/results/console.mote"),self, [:result])
        res.write template.call(result:result)
      end


      on "#{HOSTNAME}/kaya/results/report/:result_id" do |result_id|
        result = Kaya::Results::Result.get(result_id)
        res.redirect "/#{HOSTNAME}/kaya/404/There%20is%20no%20result%20for%20id=#{result_id}" if result.nil?
        result.mark_as_saw! if (result.finished? or result.stopped?)
        if result.finished? and !result.stopped? and result.html_report.size > 0
          template = Mote.parse(File.read("#{Kaya::View.path}/results/report.mote"),self, [:result])
          res.write template.call(result:result)
        else
          res.redirect "#{HOSTNAME}/kaya/results/log/result_id"
        end
      end

      on "#{HOSTNAME}/kaya/results/:result_id/reset" do |result_id|
        result = Kaya::API::Execution.reset(result_id)
        res.redirect "/#{HOSTNAME}/kaya/results?msg=#{result['message']}"
      end

      on "#{HOSTNAME}/kaya/results/suite/:suite_name" do |suite_name|
        query_string = Kaya::Support::QueryString.new req
        suite_name.gsub!("%20"," ")
        args = {suite_name:suite_name, query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

      on "#{HOSTNAME}/kaya/results/all" do
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"All Results", args:args)
      end

      on "#{HOSTNAME}/kaya/results" do
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Results", args:args)
      end

      on "#{HOSTNAME}/kaya/suites/:suite/run" do |suite_name|
        query_string = Kaya::Support::QueryString.new req
        suite_name.gsub!("%20"," ")
        result = Kaya::API::Execution.start suite_name, query_string.values
        path = if result["error"]
          "/#{HOSTNAME}/kaya/error"
        else
         "/#{HOSTNAME}/kaya/suites/#{suite_name}"
        end
        path += "?msg=#{result['message']}. " if result["message"]
        path += "Execution id=#{result["execution_id"]}" if result["execution_id"]
        res.redirect path
      end

      on "#{HOSTNAME}/kaya/suites/:suite_name" do |suite_name|
        query_string = Kaya::Support::QueryString.new req
        $K_LOG.debug "suite_name => #{suite_name}"
        suite_name.gsub!("%20"," ")
        args = {query_string:query_string, suite_name:suite_name}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Test Suites", args:args)
      end

      on "#{HOSTNAME}/kaya/suites" do
        query_string = Kaya::Support::QueryString.new req
        Kaya::Suites.update_suites
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Test Suites", args:args)
      end

      on "#{HOSTNAME}/kaya/logs/:log_name" do |log_name|
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string, log_name:log_name}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Log", args:args)
      end

      on "#{HOSTNAME}/kaya/logs" do
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Logs", args:args)
      end

      on "#{HOSTNAME}/kaya/custom/params/new" do
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string, action:"new"}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"New Custom Param", args:args)
      end

      on "#{HOSTNAME}/kaya/custom/params/:custom_id/edit" do |custom_param_id|
        query_string = Kaya::Support::QueryString.new req
        res.redirect "/#{HOSTNAME}/kaya/custom/params?msg=Could not find Custom Parameter" if Kaya::Suites::Custom::Params.exist? custom_param_id
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"edit"}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Edit Custom Param", args:args)
      end

      on "#{HOSTNAME}/kaya/custom/params/:custom_id/delete" do |custom_param_id|
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string, custom_param_id:custom_param_id, action:"delete"}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Delete Custom Param", args:args)
      end

      on "#{HOSTNAME}/kaya/custom/params" do
        query_string = Kaya::Support::QueryString.new req
        args = {query_string:query_string}
        template = Mote.parse(File.read("#{Kaya::View.path}/body.mote"),self, [:section, :args])
        res.write template.call(section:"Custom Params", args:args)
      end




# ========================================================================
# SCREENSHOTS
#
#

      on "#{HOSTNAME}/kaya/screenshot/:file_name" do |file_name|
        template = Mote.parse(File.read("#{Kaya::View.path}/screenshot.mote"),self, [:file_name])
        res.write template.call(file_name:file_name)
      end

# ========================================================================
# FEATURE SHOW
#
#
      on "#{HOSTNAME}/kaya/features/file" do
        template = Mote.parse(File.read("#{Kaya::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Kaya::Support::QueryString.new(req))
      end

# ========================================================================
# FEATURES / LIST
#
#
      on "#{HOSTNAME}/kaya/features" do
        template = Mote.parse(File.read("#{Kaya::View.path}/features.mote"),self, [:query_string])
        res.write template.call(query_string:Kaya::Support::QueryString.new(req))
      end


# ========================================================================
# API ROUTES
#
#
#
      on "#{HOSTNAME}/kaya/api/version" do
        output = { "version" => Kaya::VERSION}
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/results/:id/data" do |result_id|
        output = Kaya::API::Result.data(result_id)
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/results/:id/status" do |result_id|
        output = Kaya::API::Result.status(result_id)
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/results/:id" do |result_id|
        res.write(Kaya::API::Result.info(result_id).to_json)
      end

      on "#{HOSTNAME}/kaya/api/results/:id/reset" do |result_id|
        result = Kaya::API::Execution.reset(result_id)
        res.write result.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/:suite/run" do |suite_name|
        query_string = Kaya::Support::QueryString.new req
        result = Kaya::API::Execution.start suite_name, query_string.values
        res.write result.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/:id/status" do |suite_id|
        output = Kaya::API::Suite.status(suite_id.to_i)
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/running" do
        output = Kaya::API::Suites.list({running:true})
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/active" do
        output = Kaya::API::Suites.list({"active" => true})
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/unactive" do
        output = Kaya::API::Suites.list({"active" => false})
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites/:id" do |suite_id|
        output = Kaya::API::Suite.info(suite_id)
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/suites" do
        (Kaya::Support::Git.reset_hard and Kaya::Support::Git.pull) if Kaya::Support::Configuration.use_git?
        Kaya::Suites.update_suites
        output = Kaya::API::Suites.list({})
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/results" do
        output = Kaya::API::Results.show()
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/custom/params/:name/value" do |name|
        output = {}
        param = Kaya::API::CustomParams.get(name)
        output["app"] = Kaya::Support::Configuration.project_name
        output["request"] = "Custom Parameter value"
        output["custom_param_name"] = param["name"]
        output["value"] = param["value"]
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/custom/params/:name" do |name|
        output = {}
        param = Kaya::API::CustomParams.get(name)
        output["custom_param"] = param
        output["app"] = Kaya::Support::Configuration.project_name
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api/custom/params" do
        output ={}
        output["custom_params"] = Kaya::API::CustomParams.list()
        output["request"]="Custom Params"
        output["app"]=Kaya::Support::Configuration.project_name
        res.write output.to_json
      end


      on "#{HOSTNAME}/kaya/api/error" do
        query_string = Kaya::Support::QueryString.new req
        output = Kaya::API::Error.show(query_string)
        res.write output.to_json
      end

      on "#{HOSTNAME}/kaya/api" do
        response = {"message" => "Please, refer to /#{HOSTNAME}/kaya/help/api for more information"}
        res.write response.to_json
      end

      on "#{HOSTNAME}/kaya/error" do
        args= {query_string:Kaya::Support::QueryString.new(req), exception:nil}
        template = Mote.parse(File.read("#{Kaya::View.path}/error_handler.mote"),self, [:args])
        res.write template.call(args:args)
      end


# ========================================================================
# CLEAN
#
#
      on "#{HOSTNAME}/kaya/clean" do
        Kaya::Support::Clean.start
        res.redirect "/#{HOSTNAME}/kaya/suites?msg=Suites and results cleanned"
      end

# ========================================================================
# REDIRECTS
#
      on "#{HOSTNAME}/kaya/help" do
        res.redirect "/#{HOSTNAME}/kaya/help/main"
      end

      on "#{HOSTNAME}/kaya/404" do
        template = Mote.parse(File.read("#{Kaya::View.path}/not_found.mote"),self, [])
        res.write template.call()
      end

      on "#{HOSTNAME}/kaya/version" do
        res.redirect "#{HOSTNAME}/kaya/api/version"
      end

      on "#{HOSTNAME}/kaya/:any" do
          res.redirect("/#{HOSTNAME}/kaya/suites")
      end

      on "#{HOSTNAME}/kaya" do
        res.redirect "/#{HOSTNAME}/kaya/suites"
      end

      on "favicon" do
        res.write ""
      end

      on "#{HOSTNAME}" do
        res.redirect "/#{HOSTNAME}/kaya/suites"
      end

      on root do
        res.write "Check the url"
      end
    end



  rescue => e
    $K_LOG.error "Cuba: #{e} #{e.backtrace}" if $K_LOG
    args= {query_string:Kaya::Support::QueryString.new(req), exception:e}
    template = Mote.parse(File.read("#{Kaya::View.path}/error_handler.mote"),self, [:args])
    res.write template.call(args:args)
  end
end