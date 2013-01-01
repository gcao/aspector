# http://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns

module Dropboxed
  extend ActiveSupport::Concern

  included do
    before_create :generate_dropbox_key
  end

  def rekey_dropbox
    generate_dropbox_key
    save!
  end

  private

  def generate_dropbox_key
    self.dropbox_key = SignalId::Token.unique(24) do |key| 
      self.class.find_by_dropbox_key(key)
    end
  end
end

A.send :include, Dropboxd

##############################

class DropboxAspect < Aspector::Base
  target do
    def rekey_dropbox
      generate_dropbox_key
      save!
    end

    private

    def generate_dropbox_key
      self.dropbox_key = SignalId::Token.unique(24) do |key| 
        self.class.find_by_dropbox_key(key)
      end
    end
  end

  before :create, :generate_dropbox_key
end

DropboxAspect.apply(A)

