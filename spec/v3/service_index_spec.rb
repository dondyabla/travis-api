require 'spec_helper'

describe Travis::API::V3::ServiceIndex do
  let(:headers)  {{                        }}
  let(:path)     { '/'                      }
  let(:json)     { JSON.load(response.body) }
  let(:response) { get(path, {}, headers)   }

  describe "custom json entry point" do
    let(:expected_resources) {
      {"requests"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}/requests"}],
           "create"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/requests"}]},
         "attributes"=>["requests"]},
       "branch"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}/branch/{branch.name}"}]},
         "attributes"=>["name", "last_build", "repository"]},
       "repository"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}"}],
           "enable"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/enable"}],
           "disable"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/disable"}]},
         "attributes"=>
          ["id",
           "slug",
           "name",
           "description",
           "github_language",
           "active",
           "private",
           "owner",
           "last_build",
           "default_branch"]},
       "repositories"=>
        {"@type"=>"resource",
         "actions"=>
          {"for_current_user"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repos"}]},
         "attributes"=>["repositories"]},
       "build"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}build/{build.id}"}]},
         "attributes"=>
          ["id",
           "number",
           "state",
           "duration",
           "started_at",
           "finished_at",
           "repository",
           "branch"]},
       "organization"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}org/{organization.id}"}]},
         "attributes"=>["id", "login", "name", "github_id"]},
       "account"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}account/{account.login}"},
             {"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}account/{user.login}"},
             {"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}account/{organization.login}"}]}},
       "organizations"=>
        {"@type"=>"resource",
         "actions"=>
          {"for_current_user"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}orgs"}]},
         "attributes"=>["organizations"]},
       "user"=>
        {"@type"=>"resource",
         "actions"=>
          {"current"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}user"}],
           "find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}user/{user.id}"}]},
         "attributes"=>["id", "login", "name", "github_id", "is_syncing", "synced_at"]}}
    }

    shared_examples 'service index' do
      describe :resources do
        specify { expect(json['resources']).to include(expected_resources) }
        specify { expect(json['resources'].keys.sort) .to be == expected_resources.keys.sort }
      end
      specify { expect(json['@href']).to be == path }
    end

    describe 'with /v3 prefix' do
      let(:path) { '/v3/' }
      it_behaves_like 'service index'
    end

    describe 'with Accept header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.3+json' } }
      it_behaves_like 'service index'
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_TRAVIS_API_VERSION' => '3' } }
      it_behaves_like 'service index'
    end
  end

  describe "json-home document" do
    describe 'with /v3 prefix' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home' } }
      let(:path) { '/v3/' }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find") }
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home', 'HTTP_TRAVIS_API_VERSION' => '3' } }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find") }
    end
  end
end
