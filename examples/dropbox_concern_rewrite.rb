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

##############################

# Below aspect can be disabled completely
class DropboxAspect2 < Aspector::Base
  target do |aspect|
    define_method :rekey_dropbox do
      if aspect.disabled?
        aspect.logger.warn "Exit from rekey_dropbox because #{aspect} is disabled."
        return
      end

      generate_dropbox_key
      save!
    end

    define_method :generate_dropbox_key do
      if aspect.disabled?
        aspect.logger.warn "Exit from generate_dropbox_key because #{aspect} is disabled."
        return
      end

      self.dropbox_key = SignalId::Token.unique(24) do |key| 
        self.class.find_by_dropbox_key(key)
      end
    end

    private :generate_dropbox_key
  end

  before :create, :generate_dropbox_key
end

DropboxAspect2.apply(A)

a = A.new
aspect = DropboxAspect2.apply(a)
a.rekey_dropbox
aspect.disable
a.rekey_dropbox # Will do nothing

##############################

class DropboxAspect3 < Aspector::Base
  target do
    attr_accessor :dropbox_key
  end

  def rekey_dropbox
    if disabled?
      logger.warn "Exit from rekey_dropbox because #{self} is disabled."
      return
    end

    generate_dropbox_key
    target.save!
  end

  def generate_dropbox_key
    if disabled?
      logger.warn "Exit from generate_dropbox_key because #{self} is disabled."
      return
    end

    target.dropbox_key = SignalId::Token.unique(24) do |key|
      target.class.find_by_dropbox_key(key)
    end
  end

  before :create, :generate_dropbox_key
end

a = A.new
aspect = DropboxAspect3.apply(a)
aspect.rekey_dropbox

