# frozen_string_literal: true

module Spree
  class Image < Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    # This is where the styles are used in the app:
    # - mini: used in the BackOffice: Bulk Product edit page and Order Cycle edit page
    # - small: used in the FrontOffice: product list page
    # - product: used in the BackOffice: Product Image upload modal in the Bulk Product edit page and Product image edit page
    # - large: used in the FrontOffice: product modal
    has_attached_file :attachment,
                      styles: { mini: ["48x48#", :jpg], small: ["227x227#", :jpg],
                                product: ["240x240>", :jpg], large: ["600x600>", :jpg] },
                      default_style: :product,
                      url: '/spree/products/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/products/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace RGB' }

    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions

    include Spree::Core::S3Support
    supports_s3 :attachment

    # used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      return if attachment.errors.empty?

      errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
      false
    end

    def self.set_attachment_attributes(attribute_name, attribute_value)
      Spree::Image.attachment_definitions[:attachment][attribute_name] = attribute_value
    end

    def self.set_s3_attachment_definitions
      if Spree::Config[:use_s3]
        s3_creds = { access_key_id: Spree::Config[:s3_access_key],
                     secret_access_key: Spree::Config[:s3_secret],
                     bucket: Spree::Config[:s3_bucket] }
        Spree::Image.attachment_definitions[:attachment][:storage] = :s3
        Spree::Image.attachment_definitions[:attachment][:s3_credentials] = s3_creds
        Spree::Image.attachment_definitions[:attachment][:s3_headers] =
          ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
        Spree::Image.attachment_definitions[:attachment][:bucket] = Spree::Config[:s3_bucket]
      else
        Spree::Image.attachment_definitions[:attachment].delete :storage
      end
    end
  end
end
