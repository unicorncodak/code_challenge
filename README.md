# code_challenge

You have a json file of users.
You have a json file of companies.

Please look at these files.
Create code in Ruby that process these files and creates an
output.txt file.

Criteria for the output file.
Any user that belongs to a company in the companies file and is active
needs to get a token top up of the specified amount in the companies top up
field.

If the users company email status is true indicate in the output that the
user was sent an email ( don't actually send any emails).
However, if the user has an email status of false, don't send the email
regardless of the company's email status.

Companies should be ordered by company id.
Users should be ordered alphabetically by last name.
