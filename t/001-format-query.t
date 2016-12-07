use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Alchemy::DataNews';

my $data = Alchemy::DataNews->new(
    api_key => 'TEST',    # Doesn't run any live queries so suppress the API key warning by passing 'TEST'
);

isa_ok($data, 'Alchemy::DataNews');

subtest 'Checking methods' => sub {
    my @methods = qw(search_news next);

    can_ok($data, @methods);
};

subtest 'Format date query' => sub {
    diag "Testing format date query";

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


    diag "Testing format date query with start date and now end";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start => '07/24/2013',
            end   => 'now',
        }
    );

    $date_query = $data->_format_date_query;

    $expect = {
       end   => 'now',
       start => '1374624000'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");


    diag "Testing format date query with start date and no end";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start => '07/24/2013',
        }
    );

    $date_query = $data->_format_date_query;

    $expect = {
       end   => 'now',
       start => '1374624000'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");


    diag "Testing format date query with start date and end date";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start => '07/24/2013',
            end   => '07/26/2013',
        }
    );

    $date_query = $data->_format_date_query;

    $expect = {
       end   => '1374796800',
       start => '1374624000'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");


    diag "Testing format date query with start UTC seconds and end UTC seconds";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start => '1374624000',
            end   => '1374796800',
        }
    );

    $date_query = $data->_format_date_query;

    $expect = {
       end   => '1374796800',
       start => '1374624000'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");


    diag "Testing format date query with start UTC seconds and no end";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start => '1374624000',
        }
    );

    $date_query = $data->_format_date_query;

    $expect = {
       end   => 'now',
       start => '1374624000'
    };

    is_deeply($date_query, $expect, "Formatted data query successfully");
};

subtest 'Format fetch query' => sub {
    my $query = $data->_format_fetch_query('foo');

    is($query, 'foo', "Got a string back from string input");


    $query = $data->_format_fetch_query({ foo => 'bar' });

    is($query, 'https://gateway-a.watsonplatform.net/calls/data/GetNews?api_key=TEST&foo=bar&outputMode=json', "Got a URI back from HashRef input");


    $query = $data->_format_fetch_query({
        'q.enriched.url.title' => 'O[Obama^Biden]',
    });

    my $expect = 'https://gateway-a.watsonplatform.net/calls/data/GetNews?api_key=TEST&outputMode=json&q.enriched.url.title=O%5BObama%5EBiden%5D';

    is($query, $expect, "Got a URI back from HashRef input");
};

subtest 'Format keywords query' => sub {
    diag "Testing ArrayRefs for title and text";

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

    my $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing ArrayRefs for title and text with one custom AND join";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => ['Obama', 'Biden'],
                join  => 'AND',
            },
            {
                text => ['Trump', 'Pence'],
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => 'A[Obama^Biden]',
        'q.enriched.url.text'  => 'O[Trump^Pence]'
    };

    $keywords_query = $data->_format_keywords_query;


    diag "Testing ArrayRefs for title and text with two custom AND joins";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => ['Obama', 'Biden'],
                join  => 'AND',
            },
            {
                text => ['Trump', 'Pence'],
                join => 'AND',
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => 'A[Obama^Biden]',
        'q.enriched.url.text'  => 'A[Trump^Pence]'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing ArrayRef title and single value text";

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

    $keywords_query = $data->_format_keywords_query;

    $expect = {
        'q.enriched.url.title' => 'O[Obama^Biden]',
        'q.enriched.url.text'  => 'Trump'
    };

    is_deeply($keywords_query, $expect, "Formatted keywords query successfully");


    diag "Testing single values for title and text";

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

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing unspecified ArrayRef keyword - should default to text and OR";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [ 'Obama', 'Trump'],
    );

    $expect = {
        'q.enriched.url.text'  => 'O[Obama^Trump]'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing unspecified single value keyword - should default to text";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => 'Obama',
    );

    $expect = {
        'q.enriched.url.text'  => 'Obama'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing unspecified restricted value keyword - should default to text";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => '!Obama',
    );

    $expect = {
        'q.enriched.url.text'  => '-[Obama]'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing restricted title and unrestricted text with one value";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => '!Obama',
            },
            {
                text => 'Trump',
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => '-[Obama]',
        'q.enriched.url.text'  => 'Trump',
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing restricted title and unrestricted text with multiple values";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => '!Obama',
            },
            {
                text => ['Trump', 'Pence'],
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => '-[Obama]',
        'q.enriched.url.text'  => 'O[Trump^Pence]',
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing restricted title and unrestricted text with multiple values and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => '!Obama',
            },
            {
                text => ['Trump', 'Pence'],
                join => 'AND',
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => '-[Obama]',
        'q.enriched.url.text'  => 'A[Trump^Pence]',
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    diag "Testing restricted title and unrestricted text with multiple values and custom restricted AND join";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [
            {
                title => '!Obama',
            },
            {
                text => ['Trump', 'Pence'],
                join => '!AND',
            }
        ],
    );

    $expect = {
        'q.enriched.url.title' => '-[Obama]',
        'q.enriched.url.text'  => '-A[Trump^Pence]',
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");
};

subtest 'Format taxonomy query' => sub {

    diag "Testing ArrayRef taxonomy";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => ['Movies', 'Politics'],
    );

    my $txn_query = $data->_format_taxonomy_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]'    
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing ArrayRef taxonomy with custom AND join";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => ['Movies', 'Politics'],
        join     => 'AND',
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing single value taxonomy";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => 'Movies',
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef single value";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => {
            value => 'Movies',
        },
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with mutiple values";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value => ['Movies', 'Cars'],
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Cars]'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with mutiple values and nested custom AND join";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value => ['Movies', 'Cars'],
            join  => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Cars]'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value and confidence score and no operator";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '=0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value and confidence score and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
            operator   => '>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values and confidence score and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values and confidence score and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '>',
            join       => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value and confidence score and <";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
            operator   => '<',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value and confidence score and <";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '<',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value, custom AND join, confidence score and <";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '<',
            join       => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value, confidence score and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
            operator   => '>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, confidence score, and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, custom AND join, confidence score, and >";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '>',
            join       => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value, confidence score and =>";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
            operator   => '=>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, confidence score, and =>";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '=>',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, custom AND join, confidence score, and =>";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '=>',
            join       => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '>0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with one value, confidence score and <=";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => 'Movies',
            confidence => 0.9,
            operator   => '<=',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, confidence score, and <=";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '<=',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    diag "Testing taxonomy HashRef with multiple values, custom AND join, confidence score, and <=";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        taxonomy  => {
            value      => ['Movies', 'Politics'],
            confidence => 0.9,
            operator   => '<=',
            join       => 'AND',
        }
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
          'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'A[Movies^Politics]',
          'q.enriched.url.taxonomy.taxonomy_.score' => '<0.9'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");
};

subtest 'Format entity query' => sub {

    diag "Testing single value entity";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        entity  => { company => 'Apple' },
    );

    my $entity_query = $data->_format_entity_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.entities.entity.text' => 'Apple',
        'q.enriched.url.enrichedTitle.entities.entity.type' => 'company'
    };

    is_deeply($entity_query, $expect, "Formatted entity query successfully");


    diag "Testing ArrayRef of entities";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        entity  => { company => ['Apple', 'Microsoft'] },
    );

    $entity_query = $data->_format_entity_query;

    $expect = {
        'q.enriched.url.enrichedTitle.entities.entity.text' => 'O[Apple^Microsoft]',
        'q.enriched.url.enrichedTitle.entities.entity.type' => 'company'
    };

    is_deeply($entity_query, $expect, "Formatted entity query successfully");


    diag "Testing ArrayRef of entities with custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        entity  => { company => ['Apple', 'Microsoft'] },
        join    => 'AND',
    );

    $entity_query = $data->_format_entity_query;

    $expect = {
        'q.enriched.url.enrichedTitle.entities.entity.text' => 'A[Apple^Microsoft]',
        'q.enriched.url.enrichedTitle.entities.entity.type' => 'company'
    };

    is_deeply($entity_query, $expect, "Formatted entity query successfully");
};

subtest 'Format relations query' => sub {

    diag "Testing single value relations query";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => 'Company',
            action => 'purchased',
        },        
    );

    my $rel_query = $data->_format_relations_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=Company,action.verb.text=purchased,object.entities.entity.type=Company|'
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing ArrayRef action relations query";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => 'Company',
            action => ['purchased', 'bought'],
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=Company,action.verb.text=O[purchased^bought],object.entities.entity.type=Company|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing ArrayRef action and ArrayRef entity relations query";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => ['Company', 'Person'],
            action => ['purchased', 'bought'],
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=O[Company^Person],action.verb.text=O[purchased^bought],object.entities.entity.type=O[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing ArrayRef action and ArrayRef entity relations query";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            join   => 'AND',
            entity => ['Company', 'Person'],
            action => ['purchased', 'bought'],
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=A[purchased^bought],object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing single value action and HashRef entity relations query with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => {
                value => ['Company', 'Person'],
                join  => 'AND',
            },
            action => 'purchased',
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=purchased,object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing ArrayRef value action and HashRef entity relations query with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => {
                value => ['Company', 'Person'],
                join  => 'AND',
            },
            action => ['purchased', 'bought'],
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=O[purchased^bought],object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing HashRef value action and HashRef entity relations query with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => {
                value => ['Company', 'Person'],
                join  => 'AND',
            },
            action => { value => 'purchased' },
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=purchased,object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing HashRef with ArrayRef value and custom OR join and HashRef entity relations query with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => {
                value => ['Company', 'Person'],
                join  => 'AND',
            },
            action => {
                value => ['purchased', 'bought'],
                join  => 'OR',
            },
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=O[purchased^bought],object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");


    diag "Testing HashRef with ArrayRef value and custom OR join and HashRef entity relations query with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            entity => {
                value => ['Company', 'Person'],
                join  => 'AND',
            },
            action => {
                value => ['purchased', 'bought'],
                join  => 'AND',
            },
        },        
    );

    $rel_query = $data->_format_relations_query;

    $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=A[Company^Person],action.verb.text=A[purchased^bought],object.entities.entity.type=A[Company^Person]|',
    };

    is_deeply($rel_query, $expect, "Formatted relations query successfully");
};

subtest 'Format concept query' => sub {

    diag "Testing one value for concept";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        concept   => 'Automotive Industry', 
        timeframe => {
           start  => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    my $concept_query = $data->_format_concept_query;

    my $expect = {
        'q.enriched.url.concepts.concept.text' => 'Automotive Industry'
    };

    is_deeply($concept_query, $expect, "Formatted concept query successfully");


    diag "Testing two values for concept";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        concept   => ['Automotive Industry', 'Politics'],
        timeframe => {
           start  => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    $concept_query = $data->_format_concept_query;

    $expect = {
        'q.enriched.url.concepts.concept.text' => 'O[Automotive Industry^Politics]'
    };

    is_deeply($concept_query, $expect, "Formatted concept query successfully");


    diag "Testing HashRef as concept value";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        concept   => {
            value => 'Automotive Industry',
        },
        timeframe => {
           start  => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    $concept_query = $data->_format_concept_query;

    $expect = {
        'q.enriched.url.concepts.concept.text' => 'Automotive Industry'
    };

    is_deeply($concept_query, $expect, "Formatted concept query successfully");


    diag "Testing HashRef as concept value with ArrayRef value";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        concept   => {
            value => ['Automotive Industry', 'Politics'],
        },
        timeframe => {
           start  => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    $concept_query = $data->_format_concept_query;

    $expect = {
        'q.enriched.url.concepts.concept.text' => 'O[Automotive Industry^Politics]'
    };

    is_deeply($concept_query, $expect, "Formatted concept query successfully");


    diag "Testing HashRef as concept value with ArrayRef value and custom AND join";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        concept   => {
            value => ['Automotive Industry', 'Politics'],
            join  => 'AND',
        },
        timeframe => {
           start  => {
                date          => 'now',
                amount_before => '2',
                unit          => 'days'
            },
            end => 'now',
        }
    );

    $concept_query = $data->_format_concept_query;

    $expect = {
        'q.enriched.url.concepts.concept.text' => 'A[Automotive Industry^Politics]'
    };

    is_deeply($concept_query, $expect, "Formatted concept query successfully");
};

subtest 'Format sentiment query' => sub {

    diag "Testing one value for type and =>";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => 'positive',            
        },
    );

    my $sent_query = $data->_format_sentiment_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=positive,score=>0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing 2 values for type and =>";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
            },
            type => ['positive', 'negative'],
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[positive^negative],score=>0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing one value for type and <=";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '<=',
            },
            type => 'negative',
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=negative,score<=0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing two values for type and <=";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '<=',
            },
            type => ['negative', 'positive']
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score<=0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing one value for type and <";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '<',
            },
            type => 'negative',
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=negative,score<0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing two values for type and <";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '<',
            },
            type => ['negative', 'positive'],
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score<0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing one value for type and >";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '>',
            },
            type => 'negative',
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=negative,score>0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing two values for type and <";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '>',
            },
            type => ['negative', 'positive'],
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score>0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing one value for type and >";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => 'negative',
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=negative,score=0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");


    diag "Testing two values for type and <";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
    );

    $sent_query = $data->_format_sentiment_query;

    $expect = {
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($sent_query, $expect, "Formatted sentiment query succesfully");
};

subtest 'Testing rank queries' => sub {

    diag "Testing one rank: High";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => 'High',
    );

    my $rank_query = $data->_format_rank_query;

    my $expect = {
        'rank' => 'High',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one rank: Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => 'Medium',
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Medium',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one rank: Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => 'Low',
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Low',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one rank: Unknown";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => 'Unknown',
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Unknown',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: Unknown, High";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['Unknown', 'High']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[Unknown^High]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: Unknown, Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['Unknown', 'Medium']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[Unknown^Medium]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: Unknown, Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['Unknown', 'Low']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[Unknown^Low]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: High, Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['High', 'Medium']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[High^Medium]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: High, Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['High', 'Low']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[High^Low]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: High, Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['High', 'Unknown']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[High^Unknown]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: Medium, Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['Medium', 'Low']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[Medium^Low]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing multiple ranks: Low, Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => ['Low', 'Medium']
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[Low^Medium]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one value for HashRef: High";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => { value => 'High' },
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'High',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one value for HashRef: Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => { value => 'Medium' },
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Medium',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one value for HashRef: Low";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => { value => 'Low' },
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Low',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing one value for HashRef: Unknown";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => { value => 'Unknown' },
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'Unknown',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");


    diag "Testing two values for HashRef: High, Medium";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => { value => ['High', 'Medium'] },
    );

    $rank_query = $data->_format_rank_query;

    $expect = {
        'rank' => 'O[High^Medium]',
    };

    is_deeply($rank_query, $expect, "Formatted rank query successfully");
};

subtest 'Complex queries' => sub {

    diag "Testing one text keyword, and multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => 'Obama',
    );

    my $queries = $data->_format_queries({});

    my $expect = {
        'q.enriched.url.text'                       => 'Obama',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted keywords and sentiment correctly"); 


    diag "Testing one text keyword, one title keyword, and multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => 'Obama',
            },
            {
                title => 'Trump',
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'Trump',
        'q.enriched.url.text'  => 'Obama',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef successfully");


    diag "Testing mutiple text keywords, one title keyword, and multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => ['Obama', 'Biden'],
            },
            {
                title => 'Trump',
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'Trump',
        'q.enriched.url.text'  => 'O[Obama^Biden]',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested text ArrayRef");


    diag "Testing mutiple title keywords, one text keyword, and multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => 'Obama',
            },
            {
                title => ['Trump', 'Pence'],
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'O[Trump^Pence]',
        'q.enriched.url.text' => 'Obama',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested title ArrayRef");


    diag "Testing multiple text and title keywords, multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => ['Obama', 'Biden']
            },
            {
                title => ['Trump', 'Pence'],
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'O[Trump^Pence]',
        'q.enriched.url.text'  => 'O[Obama^Biden]',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested title and text ArrayRef");


    diag "Custom AND join on title keyword with multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => ['Obama', 'Biden'],
                join => 'AND',
            },
            {
                title => ['Trump', 'Pence'],
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'O[Trump^Pence]',
        'q.enriched.url.text'  => 'A[Obama^Biden]',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested title and text ArrayRef with AND");


    diag "Custom AND join on title keyword with multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => ['Obama', 'Biden']
            },
            {
                title => ['Trump', 'Pence'],
                join  => 'AND',
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'A[Trump^Pence]',
        'q.enriched.url.text'  => 'O[Obama^Biden]',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested title and text ArrayRef with AND");


    diag "Custom AND join on both title and text keyword with multiple sentiment types";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=',
            },
            type => ['negative', 'positive'],
        },
        keywords => [
            {
                text => ['Obama', 'Biden'],
                join => 'AND',
            },
            {
                title => ['Trump', 'Pence'],
                join  => 'AND',
            },
        ],
    );

    $queries = $data->_format_queries({});

    $expect = {
        'q.enriched.url.title' => 'A[Trump^Pence]',
        'q.enriched.url.text'  => 'A[Obama^Biden]',
        'q.enriched.url.enrichedTitle.docSentiment' => '|type=O[negative^positive],score=0.5|'
    };

    is_deeply($queries, $expect, "Formatted sentiment and keywords ArrayRef with nested title and text ArrayRef with AND");
};

subtest '__get_prefix' => sub {
    $data = Alchemy::DataNews->new(
        api_key => 'api_key',
    );

    my $prefix = $data->__get_prefix('AND');

    is($prefix, 'A', 'Got expected prefix for AND');

    $prefix = $data->__get_prefix('OR');

    is($prefix, 'O', 'Got expected prefix for OR');

    $prefix = $data->__get_prefix('!AND');

    is($prefix, '-A', 'Got expected prefix for !AND');

    $prefix = $data->__get_prefix('!OR');

    is($prefix, '-O', 'Got expected prefix for !OR');
};

subtest '__restrict_query' => sub {
    $data = Alchemy::DataNews->new(
        api_key => 'api_key',
    );

    my $restricted = $data->__restrict_query('!Obama');
    my $expect     = '-[Obama]';

    is ($restricted, $expect, "Got expected restricted query");

    $restricted = $data->__restrict_query('Obama');
    $expect     = 'Obama';

    is ($restricted, $expect, "Got expected restricted query");

};

subtest 'Test format return fields' => sub {
    $data = Alchemy::DataNews->new(
        api_key       => 'TEST',
        keywords      => 'Net Neutrality',
        return_fields => [qw(text title url)],
    );

    my $ret_fields = $data->_format_return_fields;

    my $expect = 'enriched.url.text,enriched.url.title,enriched.url.url';

    is($ret_fields, $expect, "Got expected return fields");


    $data = Alchemy::DataNews->new(
        api_key       => 'TEST',
        keywords      => 'Net Neutrality',
        return_fields => 'enriched.url.text,enriched.url.title,enriched.url.url',
    );

    $ret_fields = $data->_format_return_fields;

    $expect = 'enriched.url.text,enriched.url.title,enriched.url.url';

    is($ret_fields, $expect, "Got expected return fields");
};

subtest '_error' => sub {

    {
        my @warnings;

        local $SIG{__WARN__} = sub {
           push @warnings, @_;
        };

        $data->_error('test warn');

        is scalar(@warnings), 1, 'Just one warning';
        like $warnings[0], qr{test warn}, 'Warned ok';

        # Don't rely on array order, just get rid of the old warning
        shift @warnings;

        diag "Unsupported custom AND join";

        $data = Alchemy::DataNews->new(
            api_key => 'TEST',
            rank    => {
                value => ['High', 'Medium'],
                join  => 'AND',
            },
        );

        my $rank_query = $data->_format_rank_query;

        is scalar(@warnings), 1, 'Just one warning';

        # Without fatal set, this should default to OR
        like $warnings[0], qr{Custom AND joins are not supported in rank query! Defaulting to OR}, 'Warned ok';

        my $expect = {
            'rank' => 'O[High^Medium]',
        };

        is_deeply($rank_query, $expect, "Formatted rank query successfully");

        shift @warnings;

        diag "Test invalid timeframe - undef start and undef end";

        $data = Alchemy::DataNews->new(
            api_key  => 'TEST',
            timeframe => {
                start    => undef,
                end      => undef,
            },
            keywords => 'Net Neutrality',
        );

        my $date_query = $data->_format_date_query;

        is(scalar(@warnings), 2, 'Got two warnings');
        like $warnings[0], qr{Missing defined start date}, 'Warned ok';
        like $warnings[1], qr{Defaulting to two days from now}, 'Warned ok';

        shift @warnings;
        shift @warnings;

        diag "Test invalid timeframe - undef start and defined end";

        $data = Alchemy::DataNews->new(
            api_key   => 'TEST',
            timeframe => {
                start    => undef,
                end      => 'now',
            },
            keywords  => 'Net Neutrality',
        );

        my $date_query = $data->_format_date_query;

        is(scalar(@warnings), 2, 'Got two warnings');
        like $warnings[0], qr{Missing defined start date}, 'Warned ok';
        like $warnings[1], qr{Defaulting to two days from now}, 'Warned ok';
    }

    $data->{_fatal} = 1;

    dies_ok { $data->_error('die') }, "Died ok";

    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        rank    => {
            value => ['High', 'Medium'],
            join  => 'AND',
        },
        fatal => 1,
    );

    dies_ok { $data->_format_rank_query }, "Invalid custom AND join killed rank query ok";


    diag "Test invalid dates with fatal set";

    $data = Alchemy::DataNews->new(
        api_key   => 'TEST',
        timeframe => {
            start    => undef,
            end      => undef,
        },
        keywords => 'Net Neutrality',
        fatal    => 1,
    );

    dies_ok { $data->_format_date_query }, "Undef start and end dates kill date query ok";


    diag "Test invalid timeframe - undef start and defined end";

    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        timeframe => {
            start    => undef,
            end      => 'now',
        },
        keywords => 'Net Neutrality',
        fatal    => 1,
    );

    dies_ok { $data->_format_date_query }, "Undef start and defined end kills date query ok";
};

done_testing();
