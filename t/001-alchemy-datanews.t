use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

use_ok 'Alchemy::DataNews';

my $data = Alchemy::DataNews->new(
    api_key => $ENV{API_KEY} // 'TEST',    # Doesn't run any live queries unless $ENV{AUTHOR_TESTS} is set
);                                         # so suppress the API key warning by passing 'TEST'

isa_ok($data, 'Alchemy::DataNews');

subtest 'Checking methods' => sub {
    my @methods = qw(search_news);

    can_ok($data, @methods);
};

subtest 'Test search_news' => sub {
    plan skip_all => 'Skipping author tests' unless $ENV{AUTHOR_TESTS};

    my $result = $data->search_news({
#        sentiment => {
#            score => {
#                value    => '0.5',
#                operator => '=>',
#            },
#            type => 'positive',
#        },
        relations => {
            entity => 'Company',
            action => 'acquire',
        },
#        entity => { company => 'Apple' },
#        concept => ['Automotive Industry', 'Politics'],
#        taxonomy => ['Movies', 'Politics'],
#        keywords => 'Obama',
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
    # Testing ArrayRefs for title and text
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


    # Testing ArrayRefs for title and text with one custom AND join
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


    # Testing ArrayRefs for title and text with two custom AND joins
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


    # Testing ArrayRef title and single value text
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


    # Testing single values for title and text
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


    # Testing unspecified ArrayRef keyword - should default to text
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [ 'Obama', 'Trump'],
    );

    $expect = {
        'q.enriched.url.text'  => 'O[Obama^Trump]'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


    # Testing unspecified single value keyword - should default to text
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => 'Obama',
    );

    $expect = {
        'q.enriched.url.text'  => 'Obama'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");
};

subtest 'Format taxonomy query' => sub {
    # Testing ArrayRef taxonomy
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => ['Movies', 'Politics'],
    );

    my $txn_query = $data->_format_taxonomy_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]'    
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


    # Testing ArrayRef taxonomy with custom AND join
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


    # Testing single value taxonomy
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => 'Movies',
    );

    $txn_query = $data->_format_taxonomy_query;

    $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'Movies'
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");
};

subtest 'Format entity query' => sub {
    # Testing single value entity
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


    # Testing ArrayRef of entities
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


    # Testing ArrayRef of entities with custom AND join
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
    # Testing single value relations query
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


    # Testing ArrayRef action relations query
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


    # Testing ArrayRef action and ArrayRef entity relations query
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


    # Testing ArrayRef action and ArrayRef entity relations query
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


    # Testing single value action and HashRef entity relations query with ArrayRef value and custom AND join
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


    # Testing ArrayRef value action and HashRef entity relations query with ArrayRef value and custom AND join
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


    # Testing HashRef value action and HashRef entity relations query with ArrayRef value and custom AND join
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


    # Testing HashRef with ArrayRef value and custom OR join and HashRef entity relations
    # query with ArrayRef value and custom AND join
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


    # Testing HashRef with ArrayRef value and custom OR join and HashRef entity relations
    # query with ArrayRef value and custom AND join
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

subtest 'Format sentiment query' => sub {
    # Testing one value for type and =>
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


    # Testing 2 values for type and =>
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


    # Testing one value for type and <=
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


    # Testing two values for type and <=
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


    # Testing one value for type and <
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


    # Testing two values for type and <
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


    # Testing one value for type and >
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


    # Testing two values for type and <
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


    # Testing one value for type and >
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


    # Testing two values for type and <
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

subtest 'Complex queries' => sub {
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

subtest '_error' => sub {

    {
        my @warnings;

        local $SIG{__WARN__} = sub {
           push @warnings, @_;
        };

        $data->_error('test warn');

        is scalar(@warnings), 1, 'Just one warning';
        like $warnings[0], qr{test warn}, 'Warned ok';
    }

    $data->{_fatal} = 1;
    dies_ok { $data->_error('die') }, 'Died ok';
};

done_testing();
