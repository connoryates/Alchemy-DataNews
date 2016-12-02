# NAME

Alchemy::DataNews - Perl style queries for IBM Watson DataNews.

Coming soon to a CPAN near you...

# SYNOPSIS

```perl
use Alchemy::DataNews;

my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY
);

my $results = $alchemy->search_news({
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
    }
});

```

Example ```Dumper``` output:

```
$VAR1 = {
          'usage' => 'By accessing AlchemyAPI or using information generated by AlchemyAPI, you are agreeing to be bound by the AlchemyAPI Terms of Use: http://www.alchemyapi.com/company/terms.html',
          'totalTransactions' => '20',
          'result' => {
                        'docs' => [
                                    {
                                      'id' => 'MTY5MDkyODI0M3wxNDgwNDQ4NzUy',
                                      'timestamp' => 1480448752,
                                      'source' => {
                                                    'enriched' => {
                                                                    'url' => {
                                                                               'url' => 'http://us.hellomagazine.com/fashion/12016101918181/michelle-obama-state-dinner-looks/3/',
                                                                               'title' => 'Michelle Obama\'s White House State Dinner looks'
                                                                             }
                                                                  }
                                                  }
                                    },
                                    {
                                      'timestamp' => 1480447609,
                                      'source' => {
                                                    'enriched' => {
                                                                    'url' => {
                                                                               'url' => 'http://www.militarytimes.com/articles/time-running-out-obama-has-no-response-to-aleppo-siege',
                                                                               'title' => 'Time running out, Obama has no response to Aleppo siege'
                                                                             }
                                                                  }
                                                  },
                                      'id' => 'MTY3ODMwOTkwNHwxNDgwNDQ3NjA5'
                                    },
                                    {
                                      'id' => 'MTY3ODM1ODU4MnwxNDgwNDQ3NTk4',
                                      'source' => {
                                                    'enriched' => {
                                                                    'url' => {
                                                                               'url' => 'http://www.ohio.com/news/politics/national/trump-rollback-of-obama-climate-agenda-may-prove-challenging-1.730293',
                                                                               'title' => 'Trump rollback of Obama climate agenda may prove challenging'
                                                                             }
                                                                  }
                                                  },
                                      'timestamp' => 1480447598
                                    },
                                  ],
                        'next' => 'MTE0MDA4NTc3MDAzNDY1NDg2fE1UWTNPRE13T1Rrd05Id3hORGd3TkRRM05qQTV8OTM2OTA2OTY5NzE5MDkwNjgyfE1UWTNPVFl5TWpNeE4zd3hORGd3TkRRM05EZ3d8NzUxMzA5NTEyMjExNzE2MTYwNHx8MTUyNjY0OTU2MTMyMzgyODIwODh8TVRZM09ETTFPRFU0TW53eE5EZ3dORFEzTlRrNA',
                        'status' => 'OK'
                      },
          'status' => 'OK'
        };

```

# DESCRIPTION

Alchemy::DataNews is a client for IBM Watson's Alchemy DataNews API. The API is a very powerful REST API capable of searching keywords, semantics, tied action words, and word relationships
across given timeframes. For specific examples of what the API is capable of, please read: http://docs.alchemyapi.com/docs/

This module will map Perl syntax into the REST parameters that Watson's DataNews API uses - similar to how ```DBIC``` and ```Search::Elasticsearch```  work.

# CREDENTIALS

You will need the `username` and `password` credentials for each service. Service credentials are different from your Bluemix account username and password.

To get your service credentials, follow these steps:
 1. Log in to Bluemix at https://bluemix.net.

 1. Create an instance of the service:
     1. In the Bluemix **Catalog**, select the Watson service you want to use. For example, select the Natural Language Classifier service.
     1. Under **Add Service**, type a unique name for the service instance in the Service name field. For example, type `my-service-name`. Leave the default values for the other options.
     1. Click **Use**.

 1. Copy your credentials:
     1. On the left side of the page, click **Service Credentials** to view your service credentials.
     1. Copy `username` and `password` from these service credentials.

# CONSTRUCTOR

This module gives you the option to specify your search paramters during construction or during your method calls.

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key   => $API_KEY,
    keywords  => { title => 'Net Neutrality' },
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'hours'
        },
        end => 'now',
    }
);

$alchemy->search_news;

# -- OR --

my $alchemy = Alchemy::DataNews->new(
    api_key   => $API_KEY,
);

$alchemy->search_news({
    keywords  => { title => 'Net Neutrality' },
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'hours'
        },
        end => 'now',
    }
});

```

Note that specifying search params during the method call will overwrite any params specified during construction.

# ATTRIBUTES

```timeframe``` - Specifies a timeframe for you search. The ```start``` key indicates when your query should start looking and
allows for dynamic use of `now`. For example:

```perl
timeframe => {
    start => {
        date          => 'now',
        amount_before => '2',
        unit          => 'days'
    },
    end => 'now',
}
```

Will start the search beginning two days in the past from the current day and end on the current day. You don't have to specify an
amount before of a unit of time though, you can specify dates as well.

```keywords``` - indicates what keywords you want to match in your searches. Takes a ```HashRef```, ```ArrayRef``` of ```HashRefs```, or a ```string```.

You may specify search terms that appear in either the title or the text like so:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => [
        { title => 'Net Neutrality' },
        { text  => 'FCC' },
    ],
);
```

You can also specify multiple keywords by using an ArrayRef as the value instead of a string:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => [
        {
            title => 'Net Neutrality'
        },
        {
            text  => [
                'FCC', 'merger', 'Time Warner Cable', 'Google'
            ]
        },
    ],
);
```

The only available hash keys are ```title``` and ```text```.

If you don't specify a ```title``` or ```text```, the keywords query will default to ```text```

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => 'Net Neutrality'   # Searches text for 'Net Neutrality'
);

# --OR--

my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => ['Net Neutrality', 'FCC']   # Searches text for 'Net Neutrality' and 'FCC'
);

```


```taxonomy``` - Search based on classifications of news articles:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    taxonomy => 'Movies',
);
```

Also accepts an ArrayRef of values.



```concept``` - Specify a search query based on given concepts.

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    concept => 'Automotive Industry',
);
```

Also accepts an ArrayRef of arguments.



```entity``` - Classify a keyword as an entity of another. For example, search for "Apple" the "company":

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    entity => { company => 'Apple' },
);
```

```entity``` keys are not fixed - they describe the value and are included in the query. To search for "apple" the "fruit":

```perl
entity => { fruit => 'apple' },
```

Also accepts an ArrayRef as the nested hash value.



```relations``` - Specify a "entity" and an "action" to search. An action can be a keyword (like a verb) to refine your searches.

For example, see if a company bought anything of interest in the last 2 days:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    relations => {
        entity => 'Company',
        action => 'purchased',
    },

);
```

Both nested hash keys will accept an ArrayRef as an argument as well.

```sentiment``` - Search based on sentiment analysis of the news article:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    sentiment => {
        score => {
           value    => '0.5',
           operator => '>=',
        },
        type => 'positive',
    },
);
```

The ```score``` key corresponds to Watson's calculated sentiment score, and the opertator applies the given logic.

Valid operators are: ```>=```, ```<=```, ```<```, ```>```, and ```=```

# QUERY ATTRIBUTES

When you specify an ```ArrayRef``` as a value, the default is to search by ```OR```. You can specify ```AND``` like so:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => [
        {
            title => 'Net Neutrality'
        },
        {
            text  => [
                'FCC', 'merger', 'Time Warner Cable', 'Google'
            ]
        },
    ],
    join => 'AND',
);
```

This will then set the default search to ```AND``` for the rest of the instance.

However, each nested level will override the default, so you can specify more complex custom queries like so:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => [
        {
            title => ['Net Neutrality', 'Congress']    # Defaults to 'OR'
        },
        {
            text  => ['FCC', 'merger', 'Time Warner Cable', 'Google'],
            join => 'AND'
        },
    ],
);
```

For relations, you would specify the joins like so:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    relations => {
        entity => {
            value => ['Company', 'Corporation'],
            join  => 'AND',
        },
        action => {
            value => ['purchased', 'bought'],
            join  => 'OR',
        },
    },

);
```

For ```entity```, ```concept```,  and ```taxonomy``` queries, you may use custom ```AND``` joins with the similiar HashRef syntax as above.

```perl

$query_type => {
    value => [$value_1, $value_2],
    join  => 'AND',
},

```

In fact, if you prefer the HashRef syntax, you maybe use it without the ```join``` and it will function like you expect. This is perfectly valid:

```perl

my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    },
    relations => {
        entity => {
            value => 'Company',
        },
        action => {
            value => 'purchased',
        },
    },

);
```


```fatal``` - If a bad query parameter is passed in during construction or method call, the module will refuse
to format the query and issue a warning. This means the query will still get run, just without the bad parameter.

However, this might not return the expected results, so you can specify a ```fatal``` attribute that will cause
the code to die when it runs into a bad parameter and stop the request from going through:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    fatal   => 1,
);
```

Let's say you pass a bad parameter to the keyword key:

```perl
$alchemy->search_news({
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end  => 'now',
    }
    keywords => [
        {
            header  => ['Net Neutrality', 'Congress']    # Default to 'OR'
        },
        {
            content => ['FCC', 'merger', 'Time Warner Cable', 'Google'],
            join    => 'AND'
        },
    ],
});
```

The keys "header" and "content" will not be recognized by the method, but will still run the query with the parameters it was able to build.

```fatal``` - overrides this behaivor to ```die``` instead.

```dedup``` - ```0/1``` or ```true/false```. Removes duplicate articles from the search query.

```dedup_threshold``` - Between ```0``` and ```1``` adjust the dedup algorithm to determine how strictly a duplicate is defined

Both ```dedup``` and ```dedup_threshold``` default to ```undef```

Read more: https://alchemyapi.readme.io/docs/deduplication



```rank``` - Watson's algorithm will also rank news articles as ```Unknown```, ```Low```, ```Medium```, or ```High```. You can specify ```rank``` to filter your results:

```perl
$alchemy->search_news({
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end  => 'now',
    }
    keywords => [
        {
            title  => ['Net Neutrality', 'Congress']    # Default to 'OR'
        },
        {
            text => ['FCC', 'merger', 'Time Warner Cable', 'Google'],
            join    => 'AND'
        },
    ],
    rank => 'High',
});
```

You can also pass an ```ArrayRef``` as the value to rank, which will automatically join the values into an ```OR``` query.

Since an article cannot have more than one rank, you cannot specify custom ```AND``` joins to rank queries.

However, the ```HashRef``` syntax is still acceptable:

```perl
rank => { value => 'High' },
```

Read more: https://alchemyapi.readme.io/docs/rank-based-search


```restrictions``` - You may also specify restrictions on your queries by adding a ```!``` in front of a word. For example:


```perl
$alchemy->search_news({
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end  => 'now',
    }
    keywords => [
        {
            title  => ['Net Neutrality', 'Congress']    # Default to 'OR'
        },
        {
            text => '!FCC',
        },
    ],
    rank => 'High',
});
```

This query will exclude all articles that contain the word "FCC" in the text.

Currently, there are some limitations on query restrictions. You cannot use ```!``` inside of ```ArrayRefs``` - this will search for the literal string preceded by ```!```

You may specify a restriction within your custom ```AND``` join however. If you want to exclude words on an ```AND/OR``` basis, you can specify the query as:

```perl
$alchemy->search_news({
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end  => 'now',
    }
    keywords => [
        {
            title  => ['Net Neutrality', 'Congress'],
            join   => '!AND',   # or !OR
        },
        {
            text => '!FCC',
        },
    ],
    rank => 'High',
});
```

# INSTANCE METHODS

```search_news``` - formats and sends the REST request to Watson. By default, this method will request JSON from Watson and decode the returned JSON structure
to a Perl data structure. If you want to keep the raw output, all you need to do is specify ```raw_output => 1``` during construction or method call. Other valid
output types are ```XML``` and ```RDF``` - these are only available for ```raw_output```.


```next``` - returns the next page of results. If there is a next page of results, the previous result will contain key "next" with a token as the value that
simply needs to be appended to the previous query. This module will cache the previous query and next token (if it exists) so you can call the next page of results
like:

```perl
my $alchemy = Alchemy::DataNews->new(
    api_key => $API_KEY,
    timeframe => {
        start => {
            date          => 'now',
            amount_before => '2',
            unit          => 'days'
        },
        end => 'now',
    }
    keywords => [
        {
            title => ['Net Neutrality', 'Congress']    # Default to 'OR'
        },
        {
            text  => ['FCC', 'merger', 'Time Warner Cable', 'Google'],
            join => 'AND'
        },
    ],
);

my $next_results = $alchemy->next;
```

If you want to iterate through all pages, you can use ```next``` with a while loop:

```perl
while (my $next_results = $alchemy->next) {
    # Do the fun stuff here
}
```

The next token is cached within the ```package``` so if you need to check if there is a nect page available, the following will work:

```perl
$next_results = $alchemy->next if defined $self->{_next};
```

Note that you cannot use ```next``` with no args if you return ```raw_output```. You must parse the next token yourself and pass it to the method:

```perl
# The first argument is the query you want to see the "next" results in.
# The last query run is automatically cached, so passing in undef will default
# to the cached query.
my $next_results = $alchemy->next(undef, $parsed_token);
```

# AUTHOR

Connor Yates

# LICENSE

Perl5 - see license file
