module Travis::Api::App::Responders
  require 'securerandom'

  class Atom < Base
    ATOM_FEED_ERB = ERB.new <<-EOF
<?xml version="1.0" encoding="utf-8"?>
 
<feed xmlns="http://www.w3.org/2005/Atom">
 
  <title><%= resource.first.repository.slug %> Builds</title>
  <link href="<%= endpoint.url %>" type="application/atom+xml" rel = "self" />
  <id>urn:uuid:<%= SecureRandom.uuid %></id>
  <rights>Copyright (c) <%= DateTime.now.strftime("%Y") %> Travis CI GmbH</rights>
  <updated><%= DateTime.now.strftime %></updated>
 
  <% resource.each do |build| %>
  <entry>
    <title><%= build.repository.slug %> Build #<%= build.number %></title>
    <link href="<%= File.join("https://", Travis.config.host, build.repository.slug, "builds", build.id.to_s) %>" />
    <id>urn:uuid:<%= SecureRandom.uuid %></id>
    <updated><%= build.finished_at || build.started_at %></updated>
    <summary type="html">
    &lt;p&gt;
      <%= build.commit.message %> (<%= build.commit.committer_name %>)
      &lt;br/&gt;&lt;br/&gt;
      State: <%= build.state %>
      &lt;br/&gt;
      Started at: <%= build.started_at ? build.started_at : 'not started' %>
      &lt;br/&gt;
      Finished at: <%= build.finished_at ? build.finished_at :
        build.started_at ? 'still running' : 'not started' %>
    &lt;/p&gt;
    </summary>
    <author>
      <name><%= build.commit.committer_name %></name>
    </author>
  </entry>
  <% end %>
 
</feed>
    EOF

    def apply?
      super && resource.is_a?(ActiveRecord::Relation) && resource.first.is_a?(Build)
    end

    def apply
      super

      ATOM_FEED_ERB.result(binding)
    end

    private

    def content_type
      'application/atom+xml;charset=utf-8'
    end

  end
end
