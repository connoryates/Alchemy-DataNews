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

#subtest 'Testing search_news' => sub {
#    my $search_url = $data->search_news({
#        sentiment => {
#            score => {
#                value    => '0.5',
#                operator => '>=',
#            },
#            type => 'positive',
#        },
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
#        timeframe => {
#           start => {
#                date          => 'now',
#                amount_before => '2',
#                unit          => 'days'
#            },
#            end => 'now',
#        }
#    });

#    use Data::Dumper;
#    print "search_url => " . Dumper $search_url;
#};

subtest 'Format date query' => sub {
    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
           start => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    my $date_query = $data->_format_date_query;

    my $expect = {
       end   => 'now',
       start => 'now-2d'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");
};

subtest 'Format keywords query' => sub {
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => ['Obama', 'Biden'],
            },
            {
                text => ['Trump', 'Pence'],
            }
        ],
    );

    my $expect = {
        'q.enriched.url.title' => 'O[Obama^Biden]',
        'q.enriched.url.text'  => 'O[Trump^Pence]'
    };

    my $keyword_query = $data->_format_keyword_query;

    is_deeply($expect, $keyword_query, "Formatted keyword query successfully");

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => ['Obama', 'Biden'],
            },
            {
                text => 'Trump'
            }
        ],
    );

    $keyword_query = $data->_format_keyword_query;

    $expect = {
        'q.enriched.url.title' => 'O[Obama^Biden]',
        'q.enriched.url.text'  => 'Trump'
    };

    is_deeply($keyword_query, $expect, "Formatted keyword query successfully");

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => 'Obama'
            },
            {
                text => 'Trump'
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => 'Obama',
        'q.enriched.url.text'  => 'Trump'
    };

    $keyword_query = $data->_format_keyword_query;

    is_deeply($expect, $keyword_query, "Formatted keyword query successfully");


    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [ 'Obama', 'Trump'],
    );

    $expect = {
        'q.enriched.url.text'  => 'O[Obama^Trump]'
    };

    $keyword_query = $data->_format_keyword_query;

    is_deeply($expect, $keyword_query, "Formatted keyword query successfully");


    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => 'Obama',
    );

    $expect = {
        'q.enriched.url.text'  => 'Obama'
    };

    $keyword_query = $data->_format_keyword_query;

    is_deeply($expect, $keyword_query, "Formatted keyword query successfully");
};

subtest 'Format taxonomy query' => sub {
    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        taxonomy => ['Movies', 'Politics'],
    );

    my $txn_query = $data->_format_taxonomy_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]'    
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => 'Movies',
    );

    my $txn_query = $data->_format_taxonomy_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");
};

subtest 'Format entity query' => sub {
    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        entity => { company => 'Apple' },
    );

    my $entity_query = $data->_format_entity_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.entities.entity.text' => 'Apple',
        'q.enriched.url.enrichedTitle.entities.entity.type' => 'company'
    };

    is_deeply($entity_query, $expect, "Formatted entity query successfully");


    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        entity => { company => ['Apple', 'Microsoft'] },
    );

    $entity_query = $data->_format_entity_query;

    $expect = {
        'q.enriched.url.enrichedTitle.entities.entity.text' => 'O[Apple^Microsoft]',
        'q.enriched.url.enrichedTitle.entities.entity.type' => 'company'
    };

    is_deeply($entity_query, $expect, "Formatted entity query successfully");
};

subtest 'Format relations query' => sub {
    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            target => 'Google',
            action => 'purchased',
        },        
    );

    my $rel_query = $data->_format_relations_query;
    my $expect = '|subject.entities.entity.type=Googleacton.verb.text=purchasedobject.entities.entity.type=Google|';

    is($rel_query, $expect, "Formatted relations query successfully");
};

done_testing();
