use strict;
use warnings;

use Test::More;

use_ok 'Alchemy::DataNews';

my $data = Alchemy::DataNews->new(
    api_key => $ENV{API_KEY},
);

isa_ok($data, 'Alchemy::DataNews');

subtest 'Checking methods' => sub {
    my @methods = qw(search_news);

    can_ok($data, @methods);
};

subtest 'Testing search_news' => sub {
    my $search_url = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '>=',
            },
            type => 'positive',
        },
#        relations => {
#            target => 'Google',
#            action => 'purchased',
#        },
#        entity => { company => 'Apple' },
#        concept => ['Automotive Industry', 'Politics'],
#        taxonomy => ['Movies', 'Politics'],
#        keywords => [
#            {
#                title => ['Obama', 'Biden'],
#            },
#            {
#                text => 'Trump'
#            }
#        ],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    });

    use Data::Dumper;
    print "search_url => " . Dumper $search_url;
};

done_testing();
