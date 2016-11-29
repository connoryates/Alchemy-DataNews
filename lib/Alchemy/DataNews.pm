package Alchemy::DataNews;
# ABSTRACT: Query Watson's Alchemy DataNews API with Perl syntax

use strict;
use 5.008_005;

use Furl;
use JSON::XS qw(decode_json);
use Carp qw(cluck confess);
use URI;
use Try::Tiny;

our $VERISON = '0.01';

use constant ALCHEMY_ENDPOINT => 'https://gateway-a.watsonplatform.net/calls/data/GetNews';

our %UNIT_MAP = (
    days    => 'd',
    seconds => 's',
    minutes => 'm',
    months  => 'M',
    years   => 'y',
);

sub new {
    my ($class, %data) = @_;

    confess "No API key!" unless defined $data{api_key};

    my $self = bless {
        _timeframe       => $data{timeframe}       || undef,
        _debug           => $data{debug}           || 0,
        _max_results     => $data{max_results}     || 5,
        _rank            => $data{rank}            || undef,
        _time_slice      => $data{time_slice}      || undef,
        _dedup           => $data{dedup}           || undef,
        _dedup_threshold => $data{dedup_threshold} || undef,
        _count           => $data{count}           || 10,
        _api_key         => $data{api_key},
        _keywords        => $data{keywords}        || undef,
        _return_fields   => $data{return_fields}   || undef,
        _taxonomy        => $data{taxonomy}        || undef,
        _entity          => $data{entity}          || undef,
        _relations       => $data{relations}       || undef,
        _sentiment       => $data{sentiment}       || undef,
        _exact_match     => $data{exact_math}      || undef,
        _join            => $data{join}            || undef,
        _next            => $data{next}            || undef,   # Allow user to override next and last query if necessary
        _last_query      => $data{last_query}      || undef,
        _fatal           => $data{fatal}           || undef,
    }, $class;

    return $self;
}

sub search_news {
    my ($self, $info) = @_;

    confess "Missing required arg : info" unless defined $info;
    confess "Arg info must be a HashRef"  unless ref($info) eq 'HASH';

    # Allow the user to specify query methods on construction
    # or on method call
    $self->{_keywords}  = $info->{keywords}  if defined $info->{keywords};
    $self->{_taxonomy}  = $info->{taxonomy}  if defined $info->{taxonomy};
    $self->{_entity}    = $info->{entity}    if defined $info->{entity};
    $self->{_relations} = $info->{relations} if defined $info->{relations};
    $self->{_sentiment} = $info->{sentiment} if defined $info->{sentiment};
    $self->{_timeframe} = $info->{timeframe} if defined $info->{timeframe};

    # Query attributes
    $self->{_exact_match} = $info->{exact_match} if defined $info->{exact_match};
    $self->{_join}        = $info->{join}        if defined $info->{join};

    my $query_form   = $self->_format_date_query;
    my $formatted    = $self->_format_queries($query_form);
    my $search_query = $self->_search_news($formatted);

    $self->{_last_query} = $search_query;

    return $self->_fetch_query($search_query);
}

sub next {
    my $self  = shift;
    my $query = shift || $self->{_last_query};
    my $next  = shift || $self->{_next};

    confess "Cannot call method next without a defined next value"
      unless defined $next;

    confess "No query cached or specified" unless defined $query;

    my $uri   = URI->new($query);
    my %parts = $uri->query_form;

    $uri->query_form( %parts, next => $next );

    return $self->_fetch_query($uri->as_string);   
}

sub _fetch_query {
    my ($self, $query) = @_;

    my $content;
    try {
        my $resp = Furl->new->get($query);
        $content = decode_json($resp->content);
    } catch {
        confess "Failed to get News Alert!\nReason : $_";
    };

    # No next field if you want raw output!
    if (defined $content and ref($content) and ref($content) eq 'HASH') {
        $self->{_next} = $content->{result}->{next} || undef;
    }

    return $content;
}

sub _format_queries {
    my ($self, $query_form) = @_;

    my @query_types = qw(
        _keywords
        _taxonomy
        _concepts
        _entity
        _relations
        _sentiment
    );

    my %query_form = %$query_form;

    foreach my $query_type (@query_types) {
        next unless defined $self->{$query_type};

        my $method = '_format' . $query_type . '_query';

        if ($self->can($method)) {
            %query_form = ( %query_form, %{ $self->$method } );
        }
    }

    return \%query_form; 
}

sub _search_news {
    my ($self, $params) = @_;

    confess "Missing required arg : params" unless defined $params;
    confess "Arg params must be a HashRef" unless ref($params) eq 'HASH';

    $params->{api_key}        = $self->{_api_key};
    $params->{count}          = $self->{_count};
    $params->{outputMode}     = 'json';
    $params->{return}         = $self->_format_return_fields($self->{_return_fields});
    $params->{dedup}          = $self->{_dedup};
    $params->{next}           = $self->{_next_page};
    $params->{dedupThreshold} = $self->{_dedup_threshold};
    $params->{maxResults}     = $self->{_max_results};
    $params->{timeSlice}      = $self->{_time_slice};

    delete $params->{$_} for grep { !defined $params->{$_} } (keys %$params);

    my $uri = URI->new(ALCHEMY_ENDPOINT);
       $uri->query_form($params);

    return $uri->as_string;
}

sub _format_date_query {
    my $self = shift;

    my $timeframe = $self->{_timeframe};

    confess "Missing required param : timeframe"  unless defined $timeframe;
    confess "Arg timeframe must be a HashRef" unless ref($timeframe) eq 'HASH';

    my $start = $timeframe->{start};
    
    my $start_string;
    if (defined $start and ref($start) and ref($start) eq 'HASH') {
        my $unit = $UNIT_MAP{ $start->{unit} };

        $start_string = $start->{date} . "-" . $start->{amount_before} . $unit;
    }
    else {
        $start_string = "now-2d";
    }

    return {
        start => $start_string,
        end   => $timeframe->{end} || 'now',
    };
}

sub _format_keywords_query {
    my $self = shift;

    my $keywords = $self->{_keywords};

    confess "Missing keywords, cannot format query" unless defined $keywords;

    my $params = {};

    if (ref($keywords) and ref($keywords) eq 'ARRAY') {
        foreach my $keyword (@$keywords) {
            if (ref($keyword) and ref($keyword) eq 'HASH') {

                my $prefix;
                if (defined $keyword->{join}) {
                    # Allow custom joins
                    $prefix = $self->__get_prefix($keyword->{join});
                }

                $prefix ||= $self->__get_prefix;

                while (my ($type, $value) = each %$keyword) {
                    my $query_string;

                    if (ref($value) eq 'ARRAY') {
                        my $search_string = join '^', @$value;

                        if ($type eq 'title') {
                            $query_string = 'q.enriched.url.title';
                            $params->{$query_string} = $prefix . '[' . $search_string . ']';
                        }
                        elsif ($type eq 'text') {
                            $query_string = 'q.enriched.url.text';
                            $params->{$query_string} = $prefix . '[' . $search_string . ']';
                        }
                    }
                    else {
                        if ($type eq 'title') {
                            $query_string = 'q.enriched.url.title';
                            $params->{$query_string} = $value;
                        }
                        elsif ($type eq 'text') {
                            $query_string = 'q.enriched.url.text';
                            $params->{$query_string} = $value;
                        }
                    }
                }
            }
            else {
                my $query_string  = 'q.enriched.url.text';
                my $search_string = join '^', @$keywords;

                my $prefix = $self->__get_prefix;

                $params->{$query_string} = $prefix . '[' . $search_string . ']';
            }
        }
    }
    elsif (ref($keywords) and ref($keywords) eq 'HASH') {
        my $prefix;
        if (defined $keywords->{join}) {
            $prefix = $self->__get_prefix($keywords->{join});
        }
        while (my ($type, $value) = each %$keywords) {
            my ($query_string, $search_string);

            if (ref($value) eq 'ARRAY') {
                $search_string = join '^', @$value;
                if ($type eq 'title') {
                    $query_string = 'q.enriched.url.title';
                    $params->{$query_string} = $prefix . '[' . $search_string . ']';
                }
                elsif ($type eq 'text') {
                    $query_string = 'q.enriched.url.text';
                    $params->{$query_string} = $prefix . '[' . $search_string . ']';
                }
            }
            else {
                $query_string = 'q.enriched.url.text';
                $params->{$query_string} = $value;
            }

        }
    }
    else {
        my $query_string = 'q.enriched.url.text';
        $params->{$query_string} = $keywords;
    }

    return $params;
}

sub _format_taxonomy_query {
    my $self = shift;

    my $taxonomy = $self->{_taxonomy};

    my $params       = {};
    my $query_string = 'q.enriched.url.enrichedTitle.taxonomy.taxonomy_.label';

    if (ref($taxonomy) and ref($taxonomy) eq 'ARRAY') {
        my $search_string = join '^', @{ $taxonomy };

        my $prefix = $self->__get_prefix;

        $params->{$query_string} = $prefix . '[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = $taxonomy 
    }

    return $params;
}

sub _format_concepts_query {
    my $self = shift;

    my $concepts = $self->{_concepts};

    my $params       = {};
    my $query_string = 'q.enriched.url.concepts.concept.text';

    my $prefix = $self->__get_prefix;

    if (ref($concepts) and ref($concepts) eq 'ARRAY') {
        my $search_string = join '^', @{ $concepts };
        $params->{$query_string} = $prefix . '[' . $search_string . ']';
    }
    else {
        $params->{$query_string} = $prefix . '[' . $concepts . ']';
    }

    return $params;
}

sub _format_entity_query {
    my $self    = shift;
    my $entity = $self->{_entity};

    my $params = {};

    my $type_query   = 'q.enriched.url.enrichedTitle.entities.entity.type';
    my $entity_query = 'q.enriched.url.enrichedTitle.entities.entity.text';

    while ( my ($type, $value) = each %$entity ) {
        if (ref($value) and ref($value) eq 'ARRAY') {
            my $search_string = join '^', @{ $value };

            my $prefix = $self->__get_prefix;

            $params->{$type_query}   = $type;
            $params->{$entity_query} = $prefix . '[' . $search_string . ']';
        }
        else {
            $params->{$type_query}   = $type;
            $params->{$entity_query} = $value;
        }
    }

    return $params;
}

sub _format_relations_query {
    my $self = shift;

    my $relations = $self->{_relations};
    my $params    = {};

    # |subject.entities.entity.type=Google,action.verb.text=purchased,object.entities.entity.type=Google|
    my $query_string = 'q.enriched.url.enrichedTitle.relations.relation';

    my ($entity, $action, $orig_entity);

    if (ref($relations) and ref($relations) eq 'HASH') {

        $self->{_join} = $relations->{join} || undef;

        if (defined $relations->{entity}) {
            if (ref($relations->{entity}) and ref($relations->{entity}) eq 'ARRAY') {
                my $search_string = join '^', @{ $relations->{entity} };
                my $prefix = $self->__get_prefix;

                $search_string = $orig_entity = $prefix . '[' . $search_string . ']';
                $entity = 'subject.entities.entity.type=' . $search_string;
            }
            elsif (ref($relations->{entity}) and ref($relations->{entity}) eq 'HASH') {
                $self->{_join} = $relations->{entity}->{join} || undef;

                if (ref($relations->{entity}->{value}) and ref($relations->{entity}->{value}) eq 'ARRAY') {
                    my $search_string = join '^', @{ $relations->{entity}->{value} };
                    my $prefix = $self->__get_prefix;

                    $search_string = $orig_entity = $prefix . '[' . $search_string . ']';
                    $entity = 'subject.entities.entity.type=' . $search_string;

                    # Clear this attribute for the action query
                    $self->{_join} = undef;
                }
                elsif (!ref($relations->{entity}->{value})) {
                    $entity      = 'subject.entities.entity.type=' . $relations->{entity}->{value};
                    $orig_entity = $relations->{entity};
                }
                else {
                    $self->_error("Unsupported data type for relations entity key");
                    return undef;
                }
            }
            elsif (!ref($relations->{entity})) {
                $entity      = 'subject.entities.entity.type=' . $relations->{entity};
                $orig_entity = $relations->{entity};
            }
            else {
                $self->_error("Unsupported data type for relations key `entity`");
            }
        }
	    else {
            $self->_error("Relations query must be a HashRef and have a defined entity and action. Skipping query format");
            return undef;
	    }

        if (defined $relations->{action}) {
            if (ref($relations->{action}) and ref($relations->{action}) eq 'ARRAY') {
                my $search_string = join '^', @{ $relations->{action} };
                my $prefix = $self->__get_prefix;

                $action = 'action.verb.text=' . $prefix . '[' . $search_string . '],';
            }
            elsif (ref($relations->{action}) and ref($relations->{action}) eq 'HASH') {
                $self->{_join} = $relations->{action}->{join} || undef;

                if (ref($relations->{action}->{value}) and ref($relations->{action}->{value}) eq 'ARRAY') {
                    my $search_string = join '^', @{ $relations->{action}->{value} };
                    my $prefix = $self->__get_prefix;

                    $search_string = $prefix . '[' . $search_string . ']';
                    $action = 'action.verb.text=' . $search_string . ',';
                }
                elsif (!ref($relations->{action}->{value})) {
                    $action = 'action.verb.text=' . $relations->{action}->{value} . ',';
                }
                else {
                    $self->_error("Unsupported data type for relations key `action`");
                    return undef;
                }
            }
            elsif (!ref($relations->{action})) {
                $action = 'action.verb.text=' . $relations->{action} . ',';
            }
            else {
                $self->_error("Unsupported data type for relations key `action`");
            }
	    }
	    else {
            $self->_error("Relations query must be a HashRef and have a defined entity and action. Skipping query format");
            return undef;
	    }

        my $rel_string  = '|' . $entity . ',' . $action;
           $rel_string .= 'object.entities.entity.type=' . $orig_entity . '|';

        my $query_key   = 'q.enriched.url.enrichedTitle.relations.relation';

	    $params->{$query_key} = $rel_string;

	    return $params;
    }
    else {
        $self->_error("Unsupported data type for relations query, skipping relations query");
        return undef;
    }

    return;
}

sub _format_sentiment_query {
    my $self = shift;

    my $sentiment = $self->{_sentiment};
    my $params    = {};

    my $query_string = 'q.enriched.url.enrichedTitle.docSentiment';

    # |type=positive,score=>0.5|

    if (ref($sentiment) and ref($sentiment) eq 'HASH') {
        my $sent_string = '|type=';
 
        if (my $type = $sentiment->{type}) {
            if (ref($type) and ref($type) eq 'ARRAY') {
                my $prefix = $self->__get_prefix;
                my $search_string = join '^', @$type;
                $sent_string .= $prefix . '[' . $search_string . '],';
            }
            else {
                $sent_string .= $type . ',';
            }
        }
        else {
            $self->_error("No type key detected in sentiment query, cannot build");
            return undef;
        }

        if (my $score = $sentiment->{score}) {
            if (ref $score and ref($score) eq 'HASH') {
                my $value    = $score->{value};
                my $operator = $score->{operator};

                # API wants this style of operator
                $operator = '=>' if $operator eq '>=';

                unless ($operator =~ /(?:<|<=|=>|=|>)/) {
                    $self->_error("Invalid operator, cannot format sentiment query");
                    return undef;
                }

                $sent_string .= 'score' . $operator . $value . '|';
            }
            else {
                $self->_error("Unsupported data structure in sentiment value, cannot build sentiment query");
                return undef;
            }
        }
        else {
            $self->_error("No score key detected in sentiment query, cannot build");
            return undef;
        }

        $params->{$query_string} = $sent_string;
    }
    else {
        $self->_error("Unsupported data structure in sentiment value, cannot build sentiment query");
        return undef;
    }

    return $params;
}

sub _format_return_fields {
    my ($self, $fields) = @_;

    my $return_fields;

    if (defined $fields and ref($fields) and ref($fields) eq 'ARRAY') {
        my @fields;

        foreach my $field (@$fields) {
            if ($field eq 'title') {
                push @fields, 'enriched.url.title';
            }
            elsif ($field eq 'keywords') {
                push @fields, 'enriched.url.keywords';
            }
        }

        $return_fields = join ',', @fields;
    }
    else {
        $return_fields = 'enriched.url.keywords';
    }
    
    return 'enriched.url.url,enriched.url.title';
}

sub _error {
    my ($self, $message) = @_;

    defined $self->{_fatal}
      ? confess "$message"
      : cluck "$message";

    return;
}

sub __get_prefix {
    my $self = shift;
    my $join = shift or undef;

    $join ||= defined $self->{_join} ? $self->{_join} : 'OR';

    unless ($join =~ /(?:^\bOR\b$|^\bAND\b$)/) {
        $self->_error("Unsupported join type $join");
        cluck "Defaulting to OR";
        return 'O';
    }

    my ($prefix) = split '', $join;
    $prefix = uc($prefix);

    return $prefix;
}

1;

__END__

=encoding utf-8

=head1 NAME

Alchemy::DataNews - Query Watson's Alchemy DataNews API with Perl syntax

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Alchemy::DataNews is a client for IBM Watson's Alchemy DataNews API. The API is a very powerful
REST API capable of searching keywords, semantics, tied action words, and word relationships
across given timeframes. For specific examples of what the API is capable of, please read:
http://docs.alchemyapi.com/docs/

This module will map Perl syntax into the REST parameters that Watson's DataNews API uses - similar to how ```DBIC``` works.

=head1 CREDENTIALS

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

=head1 CONSTRUCTOR

This module gives you the option to specify your search paramters during construction or during your method calls.

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

 -- OR --

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


Note that specifying search params during the method call will overwrite any params specified during construction.

=head1 CLASS METHODS

timeframe - Specifies a timeframe for you search. The start key indicates when your query should start looking and
allows for dynamic use of `now`. For example:

  timeframe => {
      start => {
          date          => 'now',
          amount_before => '2',
          unit          => 'days'
      },
      end => 'now',
  }


Will start the search beginning two days in the past from the current day and end on the current day. You don't have to specify an
amount before of a unit of time though, you can specify dates as well.

keywords - indicates what keywords you want to match in your searches. Takes a HashRef, ArrayRef of HashRefs, or a string.

You may specify search terms that appear in either the title or the text like so:

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

You can also specify multiple keywords by using an ArrayRef as the value instead of a string:

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


For the keywords query, the only available hash keys are title and text.


taxonomy - Search based on classifications of news articles:

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

Also accepts an ArrayRef of values.

concept - Specify a search query based on given concepts.

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

Also accepts an ArrayRef of arguments.

entity - Classify a keyword as an entity of another. For example, search for "Apple" the "company":

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


Also accepts an ArrayRef as the nested hash value.

relations - Specify a "target" and an "action" to search. An action can be a keyword (like a verb) to refine your searches.

For example, see if Google bought anything of interest in the last 2 days:

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

Both nested hash keys will accept an ArrayRef as an argument as well.

sentiment - Search based on sentiment analysis of the news article:

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


The score key corresponds to Watson's calculated sentiment score, and the opertator applies the given logic.

Valid operators are: =>, <=, <, >, and =

=head1 QUERY ATTRIBUTES

When you specify an ArrayRef as a value, the default is to search by OR. You can specify AND like so:

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

This will then set the default search to AND for the rest of the instance.

However, each nested level will override the default, so you can specify more complex custom queries like so:

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

=head1 INSTANCE METHODS

search_news - formats and sends the REST request to Watson

next - returns the next page of results. If there is a next page of results, the previous result will 
contain key "next" with a token as the value that simply needs to be appended to the previous query. This
module will cache the previous query and next token (if it exists) so you can call the next page of results like:

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

If you want to iterate through all pages, you can use next with a while loop:

  while (my $next_results = $alchemy->next) {
      # Do the fun stuff here
  }

=head1 AUTHOR

Connor Yates E<lt>connor.t.yates@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Connor Yates

=head1 LICENSE

Perl5 - See LICENSE file for details

=head1 SEE ALSO

The official Alchemy Data News API documentation: http://docs.alchemyapi.com/docs/introduction

=cut
