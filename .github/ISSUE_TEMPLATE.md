<!-- 

Trouble installing the plugin under Logstash 2.4.0 with the message "duplicate gems"? See https://github.com/elastic/logstash/issues/5852

Please remember:
 - I have not used every database engine in the world
 - I have not got access to every database engine in the world
 - Any support I provide is done in my own personal time which is limited
 - Understand that I won't always have the answer immediately

Please provide as much information as possible. 

-->

<!--- Provide a general summary of the issue in the Title above -->

## Expected & Actual Behavior
<!--- If you're describing a bug, tell us what should happen, and what is actually happening, and if necessary how to reproduce it -->
<!--- If you're suggesting a change/improvement, tell us how it should work -->

## Your Environment
<!--- Include as many relevant details about the environment you experienced the bug in -->
* Version of plugin used: [ ]
* Version of Logstash used:  [ ]
* Database engine & version you're connecting to: [ ]
* Have you checked you've met the Logstash requirements for Java versions?: [ ]
* Have you checked that the JDBC jar you are using is suitable for your version of Java?: [ ]
  * If you are also using logstash-input-jdbc with an older jar please first try logstash-output-jdbc with a different newer jar.
  * The logstash-input-jdbc and logstash-output-jdbc plugins work differently and just because it works with the input plugin does not mean the same version jar will necssarily work with the output. 
