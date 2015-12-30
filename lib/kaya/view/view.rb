module Kaya
  module View

    def self.path
      File.expand_path('../', __FILE__)
    end

    def self.label_color_for result
      if result["status"]
        label_color = color result["status"]
        "<a class='label label-#{label_color}' #{access_report?(result)}>#{result['status'].capitalize}</a>"
      else
        "<a href='#' class='label label-default' >No summary</a>"
      end
    end

    def self.labels_summary_for result
      if result["results_details"]
        green = []; yellow = []; red= [];
        ["passed","failed","undefined","unknown","skipped","pending"].each do |status|
          if result["results_details"][status] && result["results_details"][status].is_a?(Array)
            case status
            when "passed"
              green = green + result["results_details"][status].map{ |a| a="<li>#{a}<\/li>" }
            when "failed", "undefined", "unknown"
              red = red + result["results_details"][status].map{ |a| a="<li>#{a}<\/li>" }
            when "skipped", "pending"
              yellow = yellow + result["results_details"][status].map{ |a| a="<li>#{a}<\/li>" }
            end
          end
        end
        if green == 0 && yellow == 0 && red == 0
          ""
        else
          "<span class='label-group'><a class='label label-success' #{access_report?(result)} data-toggle='tooltip' data-html='true' title='#{green.join("")}' >#{green.size}</a><a class='label label-warning' #{access_report?(result)} data-toggle='tooltip' data-html='true' ttitle='#{yellow.join("")}' >#{yellow.size}</a><a class='label label-danger' #{access_report?(result)} data-toggle='tooltip' data-html='true' title='#{red.join("")}' >#{red.size}</a></span>"
        end
      else
        ""
      end
    end

    def self.only_label_for result
      label_color = color result["status"]
      "<div class='label label-#{label_color}'>#{result['status'].capitalize}</div>"
    end

    def self.color value
      case value.downcase
        when /running/
          "success"
        when /finished|ready/
          "primary"
        when /(stopped|failed)/
          "danger"
        when /\d+ scenarios? \(\d+ pending\).*\d+ steps?/
          "warning"
        when /\d+ scenarios? \(\d+ passed\).*\d+ steps?/
          "success"
        when /\d+ scenarios? \(\d+ failed\).*\d+ steps?/
          "danger"
        when /(undefined|pending)/
          "warning"
        else
          "default"
      end
    end

    def self.unviewed
      '<span class="glyphicon glyphicon-eye-open" aria-hidden="true"></span>'
    end

    def self.access_report? result
      if result["status"] =~ /stopped|running/
        "onclick=\"javascript:refreshAndOpen('/#{Kaya::Support::Configuration.hostname}/kaya/results/log/#{result["_id"]}');\""
      else
        "onclick=\"javascript:refreshAndOpen('/#{Kaya::Support::Configuration.hostname}/kaya/results/report/#{result['_id']}');\"" if result["status"]=='finished' and result["has_report"]
      end
    end

    def self.label_color_for_result_id result_id
      result = Kaya::API::Result.info result_id
      self.label_color_for result if result
    end

    def self.formatted_for seconds
      hours     = seconds/ 3600
      seconds   = seconds% 3600
      minutes   = seconds/ 60
      seconds   = seconds % 60
      elapsed   = ""
      elapsed  += "#{hours} h " if hours > 0
      elapsed  += " #{minutes} m " if minutes > 0
      elapsed  += "#{seconds} s" if seconds
      "#{elapsed}"
    end

    def self.result_started_at result_id
      result = Kaya::API::Result.info result_id
      self.formatted_for result["started_at"] if result
    end
  end
end
