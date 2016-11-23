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

# CREDENTIALS

You will need the username and password credentials for each service. Service credentials are different from your Bluemix account username and password.

To get your service credentials, follow these steps:

Log in to Bluemix at https://bluemix.net.

Create an instance of the service:

In the Bluemix Catalog, select the Watson service you want to use. For example, select the Natural Language Classifier service.
Under Add Service, type a unique name for the service instance in the Service name field. For example, type my-service-name. Leave the default values for the other options.
Click Use.
Copy your credentials:

On the left side of the page, click Service Credentials to view your service credentials.
Copy username and password from these service credentials.

# DESCRIPTION

Search Watson's news database with Perl style syntax.

This module will map Perl syntax into the REST parameters that Watson's DataNews API uses, similar to how ```DBIC``` handles.

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

# CLASS METHODS

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

```keywords``` - indicates what keywords you want to match in your searches. Takes a HashRef, ArrayRef of HashRefs, or a string.

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
        { title => 'Net Neutrality' },
        { text  => ['FCC', 'merger', 'Time Warner Cable', 'Google'] },
    ],
);
```

For the keywords query, the only available hash keys are ```title``` and ```text```.

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

Also accepts an ArrayRef as the nested hash value.

```relations``` - Specify a "target" and an "action" to search. An action can be a keyword (like a verb) to refine your searches.

For example, see if Google bought anything of interest in the last 2 days:

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
        target => 'Google',
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

When you specify an ArrayRef as a value, the default is to search by OR. You can specify AND like so:

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
        { text  => ['FCC', 'merger', 'Time Warner Cable', 'Google'] },
    ],
    join => 'AND',
);
```

This will then set the default search to AND for the rest of the instance.

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
            title => 'Net Neutrality'
        },
        {
            text  => ['FCC', 'merger', 'Time Warner Cable', 'Google'],
            join => 'AND'
        },
    ],
);
```

# INSTANCE METHODS

```search_news``` - formats and sends the REST request to Watson

```next``` - returns the next page of results

# AUTHOR

Connor Yates

# LICENSE

MIT - see license file
