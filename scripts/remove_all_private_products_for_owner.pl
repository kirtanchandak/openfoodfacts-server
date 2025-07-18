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

use Modern::Perl '2017';
use utf8;

my $usage = <<TXT
update_all_products.pl is a script that updates the latest version of products in the file system and on MongoDB.
It is used in particular to re-run tags generation when taxonomies have been updated.

Usage:

remove_all_private_products_for_owner.pl --owner owner-id

owner-id is of the form org-orgid or user-userid


TXT
	;

use ProductOpener::Config qw/:all/;
use ProductOpener::Paths qw/%BASE_DIRS/;
use ProductOpener::Store qw/move_object/;
use ProductOpener::Data qw/get_products_collection/;

use Getopt::Long;

my $owner;

GetOptions("owner=s" => \$owner)
	or die("Error in command line arguments:\n\n$usage");

if ($owner !~ /^(user|org)-\S+$/) {
	die("owner must start with user- or org-:\n\n$usage");
}

print STDERR "Deleting products for owner $owner in database\n";

my $products_collection = get_products_collection();
$products_collection->delete_many({"owner" => $owner});

use File::Copy::Recursive qw(dirmove);

my $deleted_dir = "$BASE_DIRS{DELETED_PRIVATE_PRODUCTS}/$owner." . time();
# Can remove this when everything is going via Store.pm
ensure_dir_created_or_die($deleted_dir);

print STDERR "Moving data to $deleted_dir\n";

dirmove("$BASE_DIRS{IMPORT_FILES}/$owner", "$deleted_dir/import_files")
	or print STDERR "Could not move $BASE_DIRS{IMPORT_FILES}/$owner to $deleted_dir/import_files : $!\n";
dirmove("$BASE_DIRS{EXPORT_FILES}/$owner", "$deleted_dir/export_files")
	or print STDERR "Could not move $BASE_DIRS{EXPORT_FILES}/$owner to $deleted_dir/export_files : $!\n";
move_object("$BASE_DIRS{PRODUCTS}/$owner", "$deleted_dir/products");
dirmove("$BASE_DIRS{PRODUCTS_IMAGES}/$owner", "$deleted_dir/images")
	or print STDERR "Could not move $BASE_DIRS{PRODUCTS_IMAGES}/$owner to $deleted_dir/images : $!\n";

exit(0);

