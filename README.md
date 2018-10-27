# BendroCorp API

The BendroCorp API is the central data abstraction layer. All services and applications should get their data from this location.

## Endpoint Documentation
#### Keys
- (A) - Authorization Required
- (M) - Membership Required
- (R) - An additional role is required

#### Error Return/Message Return
All endpoints when they return an error or simply return a confirmation message object will return an object in the following format with a corresponding status code in the HTTP header:

```
{
  "message": string
}
```

#### User Authorization (Non-Application)
This should only be used authenticate a user as themselves. OAuth capabilities are built in and can be used for outside applications with pre-authorization.

##### `POST /auth`

Required:
```
{
  "session": {
    "email": string,
    "password": string
    "code": string (optional)
  }
}
```

Returns (User Token Object):
```
{
  "id": 0,
  "character": {
    "id": 0,
    "first_name": "John",
    "last_name": "Henry",
    "full_name": "John Henry",
    "avatar_url": "https://aws.somewhere.amazon.com/......"
  },
  "tfa_enabled": false,
  "token":
  "token_expires": 1540675330
  claims: [
    "id": 0,
    "name": "Member"
  ]
}
```

#### Account
##### `POST /api/account/change-password` (A)

Update the current authorized users password.

Required:

```
{
  "password": {
    "original_password": "12345",
    "password": "123456",
    "password_confirmation": "123456"
  }
}
```

Returns:

A message object

##### `GET api/account/fetch-tfa` (Auth Required)
Start the process for enabling two factor authentication for the current authorized user. Must be called prior to called the `enable-tfa` endpoint to initialize the TOTP seed value.

Returns:

```
{
  "qr_data_string": "otpauth://totp/bendrocorp?secret=<auth secret>",
  "seed_value": "<auth secret>"
}
```

##### `POST api/account/enable-tfa` (Auth Required)
Enable two-factor authentication for the current authorized user.

Required:

```
{
  "two_factor_auth": {
    "password": "MyCurrentPassword123" // current password
    "code": "123456" // valid two factor code based on assigned seed value
  }
}
```

Returns:

A message object

#### Admin
TODO

#### Alerts
##### `GET api/alert` (Auth Required)

Returns:
```
[
  {
    "id": 0,
    "message": "A message"
    "system_id": 0,
    "planet_id": 0,
    "moon_id": 0
  }
]
```

##### `POST api/alert` (Auth Required) (Role Required)
Create a new alert

Required:
```
{
  "message": "A message"
  "system_id": 0,
  "planet_id": 0,
  "moon_id": 0
}
```

Returns:
```
{
  "id": 0
  "message": "A message"
  "system_id": 0,
  "planet_id": 0,
  "moon_id": 0
}
```

##### `PATCH api/alert` (Auth Required) (Role Required)
Update a current alert. Very similar to creating a new alert except that you need to include the ID for the alert you want to update.

Required:
```
{
  "id": 0
  "message": "A message"
  "system_id": 0,
  "planet_id": 0,
  "moon_id": 0
}
```

Returns:
```
{
  "id": 0
  "message": "A message"
  "system_id": 0,
  "planet_id": 0,
  "moon_id": 0
}
```

##### `DELETE api/alert/:id` (Auth Required) (Role Required)
Delete a current alert. Alert deletions are not soft deletions.

Returns:

A message object

#### Membership Applications
##### `POST api/apply` (Auth Required)
Create an application for the the current authorized user. The current authorized must not already be a member.

Required:
```
{
  character: {
    first_name: "first name",
    last_name: "last name",
    description: "description",
    background: "background",
    user_attributes: {
      rsi_handle: "user123"
    },
    owned_ships_attributes: {
        "ship_id": 0,
        "title": "A ship title"
    },
    application_attributes: {
      "tell_us_about_the_real_you": "blurb here"
      "why_do_want_to_join": "blurb here"
      "how_did_you_hear_about_us": "blurb here"
      "job_id": 0
    }
  }
}
```

##### `GET api/apply` (Auth Required)
Get the application for the current authorized user.

Returns:

```
{
    "id": 1,
    "tell_us_about_the_real_you": "Some text",
    "why_do_want_to_join": "Some text",
    "how_did_you_hear_about_us": "Some text",
    "application_interview_id": 1,
    "application_status_id": 6,
    "last_status_change": null,
    "last_status_changed_by_id": 2,
    "job_id": 1,
    "character_id": 1,
    "approval_approval_request_id": 1,
    "application_status": {
        "id": 6,
        "title": "Accepted",
        "description": "Your application has been accepted. You will be contacted by the Director of Human Resources and your respective division Director shortly.",
        "ordinal": 6
    }
}
```

##### `DELETE api/apply` (Auth Required)
Withdrawn the application for the current authorized user. Note: Current members cannot withdraw their application as they are already members.

Returns:

A message object

##### `GET /api/apply/:character_id/advance` (Auth Required) (Role Required)
Advance the application of the character with the id bound to `:character_id`. HR or CEO role are required to advance an application.

Returns:

A message object

##### `PATCH api/apply` (Auth Required) (Role Required)
Update an application interview packet assigned to a particular application. This does allow the application object itself to updated.

Required:
```
{
  interview: {
    id: number
    tell_us_about_yourself:string ,
    applicant_has_read_soc: boolean,
    applicant_agrees_to_respect_for_leadership: boolean,
    applicant_agrees_to_voice_policy: boolean,
    applicant_agrees_to_roleplay_style: boolean,
    applicant_agrees_to_follow_all_policies: boolean,
    applicant_agrees_to_understands_participation: boolean,
    why_selected_division: string,
    why_join_bendrocorp: string,
    applicant_questions: string,
    interview_consensous: string,
    locked_for_review: boolean
  }
}
```

Returns:

A message object

##### `GET /api/apply/:character_id/reject` (Auth Required) (Role Required)
Reject the application for the character/user with the id bound to `:character_id`.

Returns:

A message object

#### Approvals
##### `GET api/approvals/:approval_id/:approval_type` (Auth Required)
As the current user attempt to change your approval status with the approval type id bound to `:approval_type` for the approval whose id is bound to `:approval_id`. If the user authorized user is not an approver of the provided `:approval_id` an error code will be returned.

Returns:

A message object

#### Divisions
##### `GET api/division` (A) (M)
Get an array of all of the current Divisions within BendroCorp.

## Development

## Contributions
