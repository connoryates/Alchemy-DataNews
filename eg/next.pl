#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use Alchemy::DataNews;
use Data::Dumper;

my $alchemy = Alchemy::DataNews->new(
    api_key => $ENV{API_KEY},
);

my $result = $alchemy->search_news({
    entity    => { company => 'Apple' },
    sentiment => {
        score => {
            value    => '0.5',
            operator => '=>',
        },
        type => 'positive',            
    },
    timeframe => {
        start  => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'            
        },
        end => 'now',
    },
    rank => 'High',
});

while (my $next_result = $alchemy->next) {
    print Dumper $next_result;
}


exit(0);
