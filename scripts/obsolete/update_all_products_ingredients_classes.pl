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

use CGI::Carp qw(fatalsToBrowser);

use Modern::Perl '2017';
use utf8;

use ProductOpener::Config qw/:all/;
use ProductOpener::Paths qw/:all/;
use ProductOpener::Store qw/:all/;
use ProductOpener::Index qw/:all/;
use ProductOpener::Display qw/:all/;
use ProductOpener::Tags qw/:all/;
use ProductOpener::Users qw/:all/;
use ProductOpener::Images qw/:all/;
use ProductOpener::Lang qw/:all/;
use ProductOpener::Mail qw/:all/;
use ProductOpener::Products qw/:all/;
use ProductOpener::Food qw/:all/;
use ProductOpener::Ingredients qw/:all/;
use ProductOpener::Images qw/:all/;


use CGI qw/:cgi :form escapeHTML/;
use URI::Escape::XS;
use Storable qw/dclone/;
use Encode;
use JSON::MaybeXS;


# Get a list of all products

my $class = 'additives';

open (my $OLD, q{>}, "$www_root/images/$class.old.html");
open (my $NEW, q{>}, "$www_root/images/$class.new.html");


my $cursor = $products_collection->query({})->fields({ code => 1 })->sort({code =>1});
	
	while (my $product_ref = $cursor->next) {
        
		
		my $code = $product_ref->{code};
		my $path = product_path($code);
		
		print STDERR "updating product $code\n";
		
		$product_ref = retrieve_product($code);
		
		# Update
		extract_additives_from_text($product_ref);

		# Store
		
		next if $path =~ /invalid/;

		if (object_exists("$BASE_DIRS{PRODUCTS}/$path/product")) {
			store_object("$BASE_DIRS{PRODUCTS}/$path/product", $product_ref );
			$products_collection->save($product_ref);

			if (defined $product_ref->{old_additives_tags}) {
				print $OLD "<a href=\"" . product_url($product_ref) . "\">$product_ref->{code} - $product_ref->{name}</a> : " . join (" ", sort @{$product_ref->{old_additives_tags}}) . "<br />\n";
			}
			if (defined $product_ref->{new_additives_tags}) {
				print $NEW "<a href=\"" . product_url($product_ref) . "\">$product_ref->{code} - $product_ref->{name}</a> : " . join (" ", sort @{$product_ref->{new_additives_tags}}) . "<br />\n";
			}
		}
	}

close $OLD;
close $NEW;

exit(0);

