use strict;
use warnings;

use Test::More;
use Data::Dumper;

plan skip_all => 'No API key' unless $ENV{API_KEY};

use_ok 'Alchemy::DataNews';

my $data = Alchemy::DataNews->new(
    api_key => $ENV{API_KEY}
);

isa_ok($data, 'Alchemy::DataNews');

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        taxonomy => {
            value      => ['movies', 'politics'],
            confidence => 0.7,
            operator   => '>',
        },
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Medium', 'Low'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        taxonomy => {
            value      => 'movies',
            confidence => 0.7,
            operator   => '>',
        },
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Medium', 'Low'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        entity => { company => 'Apple' },
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Medium', 'Low'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        concept => ['Automotive Industry', 'Politics'],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Low', 'Medium'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        keywords => [
            {
                title => ['Obama', 'Biden'],
                join  => 'AND',
            },
            {
                text => 'Trump'
            }
        ],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => 'High',
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        keywords => [
            {
                title => ['Obama', 'Biden'],
            },
            {
                text => 'Trump'
            }
        ],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        taxonomy => {
            value      => 'movies',
            confidence => 0.7,
            operator   => '>',
            join       => 'AND',
        },
        keywords => 'Obama',
        keywords => [
            {
               title => ['Obama', 'Biden'],
            },
            {
                text => 'Trump'
            }
        ],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Low', 'Medium'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',
        },
        keywords => 'Congress',
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => 'High',
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};
subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        entity => { company => 'Apple' },
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => 'High',
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        sentiment => {
            score => {
                value    => '0.5',
                operator => '<=',
            },
            type => 'negative',
        },
        concept => ['Automotive Industry', 'Politics'],
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => 'High',
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test search_news' => sub {

    my $result = $data->search_news({
        relations => {
            entity => 'Company',
            action => 'acquire',
        },
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        rank => ['High', 'Medium', 'Low'],
    });

    is(defined $result, 1, "Got a result back from request");

    print Dumper $result;
};

subtest 'Test next' => sub {
    plan skip_all => 'Skipping author tests' unless $ENV{AUTHOR_TESTS};

    if (not defined $data->{_next}) {
        $data->search_news({
            keywords => {
                text => 'Trump'
            },
            timeframe => {
               start => {
                    date          => 'now',
                    amount_before => '2',
                    unit          => 'days'
                },
                end => 'now',
            }
        });
    }

    my $next_result = $data->next;

    is(defined $next_result, 1, "Got a result back from request");

    print Dumper $next_result;
};

subtest 'Test raw output' => sub {
    plan skip_all => 'Skipping author tests' unless $ENV{AUTHOR_TESTS};

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        },
        raw_output => 1,
    );

    my $result = $data->search_news;

    is(defined $result, 1, 'Got a scalar back from JSON raw output');
};

done_testing();
