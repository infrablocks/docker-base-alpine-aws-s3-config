require 'spec_helper'

describe 'commands' do
  before(:all) do
    set :backend, :docker
    set :docker_image, "alpine-aws-s3-config:latest"
    set :docker_container_create_options, {
        "Entrypoint" => "/bin/sh"
    }
  end

  ['bash', 'curl', 'dumb-init'].each do |apk|
    it "includes #{apk}" do
      expect(package(apk)).to be_installed
    end
  end
end
