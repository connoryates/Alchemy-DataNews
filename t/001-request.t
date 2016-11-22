use strict;
use warnings;

use Test::More;

use_ok 'Alchemy::DataNews';

my $data = Alchemy::DataNews->new(
    # api_key => 'a4648cd7f4adf7712c41a4563d618dd65f2ca4be',
    api_key => '899037d290dbf55145ab97ebccaae88d68b84210',
);

isa_ok($data, 'Alchemy::DataNews');

subtest 'Checking methods' => sub {
    my @methods = qw(search_news);

    can_ok($data, @methods);
};

subtest 'Testing search_news' => sub {
    my $search_url = $data->search_news({
        # Default to searching text?
        sentiment => {
            score => {
                value    => '0.5',
                operator => '>=',
            },
            type => 'positive',
        },
        relations => {
            target => 'Google',
            action => 'purchased',
        },
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
