use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Alchemy::DataNews';
use_ok 'Data::Dumper';

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
        sentiment => {
            score => {
                value    => '0.5',
                operator => '=>',
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


    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        keywords => [ 'Obama', 'Trump'],
    );

    $expect = {
        'q.enriched.url.text'  => 'O[Obama^Trump]'
    };

    $keywords_query = $data->_format_keywords_query;

    is_deeply($expect, $keywords_query, "Formatted keywords query successfully");


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
    $data = Alchemy::DataNews->new(
        api_key  => 'TEST',
        taxonomy => ['Movies', 'Politics'],
    );

    my $txn_query = $data->_format_taxonomy_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label' => 'O[Movies^Politics]'    
    };

    is_deeply($txn_query, $expect, "Formatted taxonomy query successfully");


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
    $data = Alchemy::DataNews->new(
        api_key => 'TEST',
        relations => {
            target => 'Google',
            action => 'purchased',
        },        
    );

    my $rel_query = $data->_format_relations_query;

    my $expect = {
        'q.enriched.url.enrichedTitle.relations.relation' =>
          '|subject.entities.entity.type=Googleacton.verb.text=purchasedobject.entities.entity.type=Google|'
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
