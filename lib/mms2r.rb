#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information.
#++

$:.unshift(File.dirname(__FILE__) + "/vendor/")
require 'mms2r/media'
require 'mms2r/cingular_me_media'
require 'mms2r/dobson_media'
require 'mms2r/m_mode_media'
require 'mms2r/my_cingular_media'
require 'mms2r/nextel_media'
require 'mms2r/sprint_media'
require 'mms2r/sprint_pcs_media'
require 'mms2r/t_mobile_media'
require 'mms2r/verizon_media'
require 'mms2r/vtext_media'

module MMS2R

  ##
  # A hash of carriers that MMS2r is currently aware of.
  # The factory create method uses the hostname portion
  # of an MMS's From header to select the correct type
  # of MMS2R::Media product.  If a specific media product
  # is not available MMS2R::Media should be used.

  CARRIER_CLASSES = {
    'cingularme.com' => MMS2R::CingularMeMedia,
    'mms.dobson.net' => MMS2R::DobsonMedia,
    'mmode.com' => MMS2R::MModeMedia,
    'mms.mycingular.com' => MMS2R::MyCingularMedia,
    'messaging.nextel.com' => MMS2R::NextelMedia,
    'pm.sprint.com' => MMS2R::SprintMedia,
    'messaging.sprintpcs.com' => MMS2R::SprintPcsMedia,
    'tmomail.net' => MMS2R::TMobileMedia,
    'vzwpix.com' => MMS2R::VerizonMedia,
    'vtext.com' => MMS2R::VtextMedia
  }

  ##
  # A hash of file extensions for common mimetypes

  EXT = {
    'text/plain' => 'txt',
    'text/html' => 'html',
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/jpeg' => 'jpg',
    'video/quicktime' => 'mov',
    'video/3gpp2' => '3g2'
  }

  class MMS2R::Media

    ##
    # MMS2R Library version

    VERSION = '1.1.2'

    end

end
