#!/usr/bin/perl -w

# This file is part of Product Opener.
#
# Product Opener
# Copyright (C) 2011-2023 Association Open Food Facts
# Contact: contact@openfoodfacts.org
# Address: 21 rue des Iles, 94100 Saint-Maur des Fossés, France
#
# Product Opener is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use ProductOpener::PerlStandards;

use CGI::Carp qw(fatalsToBrowser);

use ProductOpener::Config qw/:all/;
use ProductOpener::Store qw/:all/;
use ProductOpener::Index qw/:all/;
use ProductOpener::Display qw/init_request/;
use ProductOpener::HTTP qw/write_cors_headers single_param/;
use ProductOpener::Tags qw/:all/;
use ProductOpener::Users qw/$Owner_id $User_id %User/;
use ProductOpener::Images qw/is_protected_image process_image_unselect get_image_type_and_image_lc_from_imagefield/;
use ProductOpener::Products qw/normalize_code product_id_for_owner retrieve_product store_product/;

use CGI qw/:cgi :form escapeHTML/;
use URI::Escape::XS;
use Storable qw/dclone/;
use Encode;
use JSON::MaybeXS;
use Log::Any qw($log);

my $request_ref = ProductOpener::Display::init_request();

my $type = single_param('type') || 'add';
my $action = single_param('action') || 'display';

my $code = normalize_code(single_param('code'));
my $id = single_param('id');

my ($image_type, $image_lc) = get_image_type_and_image_lc_from_imagefield($id);

my $product_id = product_id_for_owner($Owner_id, $code);
my $product_ref = retrieve_product($product_id);

$log->debug("start", {code => $code, id => $id}) if $log->is_debug();

if (not defined $code) {

	exit(0);
}

if (not is_protected_image($product_ref, $image_type, $image_lc) or $User{moderator}) {
	process_image_unselect($product_ref, $image_type, $image_lc);
	store_product($User_id, $product_ref, "unselected image ${image_type}_{$image_lc}");
}

my $data = encode_json({status_code => 0, status => 'status ok', imagefield => $id});

$log->debug("JSON data output", {data => $data}) if $log->is_debug();

write_cors_headers();

print header(
	-type => 'application/json',
	-charset => 'utf-8',
) . $data;

exit(0);

