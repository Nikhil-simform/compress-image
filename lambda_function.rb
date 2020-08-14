require 'json'
require "aws-sdk-s3"
require "mini_magick"



def lambda_handler(event:, context:)
    event = event["Records"].first
    bucket_name = event["s3"]["bucket"]["name"]
    object_name = event["s3"]["object"]["key"]

    s3 = Aws::S3::Resource.new()

    object = s3.bucket(bucket_name).object(object_name)
    download_path = "/tmp/#{object_name}"
    object.get(response_target: download_path)

    thumbnail_upload_path = "/tmp/#{object_name}-thumbnail"
    compress_upload_path = "/tmp/#{object_name}-compressed"
    
    resize_image(download_path, thumbnail_upload_path, compress_upload_path)
    
    s3.bucket("image-resize-test123-thumbnail").object(object_name).upload_file(thumbnail_upload_path)
    s3.bucket("image-resize-test123-compressed").object(object_name).upload_file(compress_upload_path)
    

end

def resize_image(image_path, thumbnail_upload_path, compress_upload_path)
    thumbnail_image = MiniMagick::Image.open(image_path)
    compress_image = MiniMagick::Image.open(image_path)
    
    thumbnail_image.resize "x100"
    thumbnail_image.write(thumbnail_upload_path)
    
    compress_image.strip
    compress_image.quality "40%"
    compress_image.sampling_factor "4:2:0"
    compress_image.interlace "Plane"
    compress_image.gaussian_blur "0.05"
    
    if compress_image.size > 2000000
        compress_image.resize "25%"
    end
    compress_image.write(compress_upload_path)
end
