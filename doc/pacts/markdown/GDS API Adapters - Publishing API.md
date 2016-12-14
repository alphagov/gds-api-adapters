### A pact between GDS API Adapters and Publishing API

#### Requests from GDS API Adapters to Publishing API

* [A publish request](#a_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7) given a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7

* [A publish request](#a_publish_request_given_a_published_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7) given a published content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7

* [A publish request](#a_publish_request_given_both_content_stores_and_url-arbiter_empty) given both content stores and url-arbiter empty

* [A publish request](#a_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7_which_does_not_have_a_publishing_app) given a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 which does not have a publishing_app

* [A request for a non-existent content item](#a_request_for_a_non-existent_content_item_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request from the Whitehall application to create a content item at /test-item](#a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_in_url-arbiter_by_the_Publisher_application) given /test-item has been reserved in url-arbiter by the Publisher application

* [A request to create a content item](#a_request_to_create_a_content_item_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to create a content item without links](#a_request_to_create_a_content_item_without_links_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to create a draft content item](#a_request_to_create_a_draft_content_item_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to create a publish intent](#a_request_to_create_a_publish_intent_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to create an invalid content-item](#a_request_to_create_an_invalid_content-item_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to delete a publish intent](#a_request_to_delete_a_publish_intent_given_a_publish_intent_exists_at_/test-intent_in_the_live_content_store) given a publish intent exists at /test-intent in the live content store

* [A request to delete a publish intent](#a_request_to_delete_a_publish_intent_given_both_content_stores_and_the_url-arbiter_are_empty) given both content stores and the url-arbiter are empty

* [A request to return the content item](#a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7) given a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7

* [An invalid publish request](#an_invalid_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7) given a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7

#### Interactions

<a name="a_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7"></a>
Given **a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7**, upon receiving **a publish request** from GDS API Adapters, with
```json
{
  "method": "post",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7/publish",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 200
}
```
<a name="a_publish_request_given_a_published_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7"></a>
Given **a published content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7**, upon receiving **a publish request** from GDS API Adapters, with
```json
{
  "method": "post",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7/publish",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 400,
  "body": {
    "error": {
      "code": 400,
      "message": "Cannot publish an already published content item"
    }
  }
}
```
<a name="a_publish_request_given_both_content_stores_and_url-arbiter_empty"></a>
Given **both content stores and url-arbiter empty**, upon receiving **a publish request** from GDS API Adapters, with
```json
{
  "method": "post",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7/publish",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 404
}
```
<a name="a_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7_which_does_not_have_a_publishing_app"></a>
Given **a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 which does not have a publishing_app**, upon receiving **a publish request** from GDS API Adapters, with
```json
{
  "method": "post",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7/publish",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 422,
  "body": {
    "error": {
      "code": 422,
      "fields": {
        "publishing_app": [
          "can't be blank"
        ]
      }
    }
  }
}
```
<a name="a_request_for_a_non-existent_content_item_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request for a non-existent content item** from GDS API Adapters, with
```json
{
  "method": "get",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7"
}
```
Publishing API will respond with:
```json
{
  "status": 404,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "error": {
      "code": 404,
      "message": "not found"
    }
  }
}
```
<a name="a_request_from_the_Whitehall_application_to_create_a_content_item_at_/test-item_given_/test-item_has_been_reserved_in_url-arbiter_by_the_Publisher_application"></a>
Given **/test-item has been reserved in url-arbiter by the Publisher application**, upon receiving **a request from the Whitehall application to create a content item at /test-item** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "base_path": "/test-item",
    "content_id": "bed722e6-db68-43e5-9079-063f623335a7",
    "title": "Instructions for crawler robots",
    "description": "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
    "format": "special_route",
    "public_updated_at": "2015-07-30T13:58:11.000Z",
    "publishing_app": "whitehall",
    "rendering_app": "static",
    "routes": [
      {
        "path": "/test-item",
        "type": "exact"
      }
    ],
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 409,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "error": {
      "code": 409,
      "message": "Conflict",
      "fields": {
        "base_path": [
          "is already in use by the 'publisher' app"
        ]
      }
    }
  }
}
```
<a name="a_request_to_create_a_content_item_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to create a content item** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/content/test-content-item",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "title": "Test content item",
    "description": "Description for /test-content-item",
    "format": "guide",
    "need_ids": [
      "100001"
    ],
    "public_updated_at": "2014-05-06T12:01:00+00:00",
    "details": {
      "body": "Some content for /test-content-item"
    },
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "title": "Test content item",
    "description": "Description for /test-content-item",
    "format": "guide",
    "need_ids": [
      "100001"
    ],
    "public_updated_at": "2014-05-06T12:01:00+00:00",
    "details": {
      "body": "Some content for /test-content-item"
    },
    "update_type": "major"
  }
}
```
<a name="a_request_to_create_a_content_item_without_links_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to create a content item without links** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "base_path": "/robots.txt",
    "content_id": "bed722e6-db68-43e5-9079-063f623335a7",
    "title": "Instructions for crawler robots",
    "description": "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
    "format": "special_route",
    "public_updated_at": "2015-07-30T13:58:11.000Z",
    "publishing_app": "static",
    "rendering_app": "static",
    "routes": [
      {
        "path": "/robots.txt",
        "type": "exact"
      }
    ],
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 200
}
```
<a name="a_request_to_create_a_draft_content_item_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to create a draft content item** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/draft-content/test-draft-content-item",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "title": "Test draft content item",
    "description": "Description for /test-draft-content-item",
    "format": "guide",
    "need_ids": [
      "100001"
    ],
    "public_updated_at": "2014-05-06T12:01:00+00:00",
    "details": {
      "body": "Some content for /test-draft-content-item"
    },
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "title": "Test draft content item",
    "description": "Description for /test-draft-content-item",
    "format": "guide",
    "need_ids": [
      "100001"
    ],
    "public_updated_at": "2014-05-06T12:01:00+00:00",
    "details": {
      "body": "Some content for /test-draft-content-item"
    },
    "update_type": "major"
  }
}
```
<a name="a_request_to_create_a_publish_intent_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to create a publish intent** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/publish-intent/test-intent",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "base_path": "/test-intent",
    "publish_time": "2014-05-06T12:01:00+00:00"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  }
}
```
<a name="a_request_to_create_an_invalid_content-item_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to create an invalid content-item** from GDS API Adapters, with
```json
{
  "method": "put",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "base_path": "not a url path",
    "content_id": "bed722e6-db68-43e5-9079-063f623335a7",
    "title": "Instructions for crawler robots",
    "description": "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
    "format": "special_route",
    "public_updated_at": "2015-07-30T13:58:11.000Z",
    "publishing_app": "static",
    "rendering_app": "static",
    "routes": [
      {
        "path": "not a url path",
        "type": "exact"
      }
    ],
    "update_type": "major"
  }
}
```
Publishing API will respond with:
```json
{
  "status": 422,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "error": {
      "code": 422,
      "message": "Unprocessable entity",
      "fields": {
        "base_path": [
          "is invalid"
        ]
      }
    }
  }
}
```
<a name="a_request_to_delete_a_publish_intent_given_a_publish_intent_exists_at_/test-intent_in_the_live_content_store"></a>
Given **a publish intent exists at /test-intent in the live content store**, upon receiving **a request to delete a publish intent** from GDS API Adapters, with
```json
{
  "method": "delete",
  "path": "/publish-intent/test-intent"
}
```
Publishing API will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  }
}
```
<a name="a_request_to_delete_a_publish_intent_given_both_content_stores_and_the_url-arbiter_are_empty"></a>
Given **both content stores and the url-arbiter are empty**, upon receiving **a request to delete a publish intent** from GDS API Adapters, with
```json
{
  "method": "delete",
  "path": "/publish-intent/test-intent"
}
```
Publishing API will respond with:
```json
{
  "status": 404,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  }
}
```
<a name="a_request_to_return_the_content_item_given_a_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7"></a>
Given **a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7**, upon receiving **a request to return the content item** from GDS API Adapters, with
```json
{
  "method": "get",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7"
}
```
Publishing API will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json; charset=utf-8"
  },
  "body": {
    "content_id": "bed722e6-db68-43e5-9079-063f623335a7",
    "format": "special_route",
    "publishing_app": "publisher",
    "rendering_app": "frontend",
    "locale": "en",
    "routes": [
      {
      }
    ],
    "public_updated_at": "2015-07-30T13:58:11.000Z",
    "details": {
    }
  }
}
```
<a name="an_invalid_publish_request_given_a_draft_content_item_exists_with_content_id:_bed722e6-db68-43e5-9079-063f623335a7"></a>
Given **a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7**, upon receiving **an invalid publish request** from GDS API Adapters, with
```json
{
  "method": "post",
  "path": "/v2/content/bed722e6-db68-43e5-9079-063f623335a7/publish",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "update_type": ""
  }
}
```
Publishing API will respond with:
```json
{
  "status": 422,
  "body": {
    "error": {
      "code": 422,
      "message": "Unprocessable entity",
      "fields": {
        "update_type": [
          "is required"
        ]
      }
    }
  }
}
```
