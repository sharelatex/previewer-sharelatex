assert = require("chai").assert
sinon = require('sinon')
chai = require('chai')
should = chai.should()
expect = chai.expect
SandboxedModule = require('sandboxed-module')
request = require("request")
settings = require("settings-sharelatex")
express = require('express')
Router = require('../../../app/js/Router')
FakeFileStore = require('./helpers/FakeFileStore')

describe "Previewer", ->

	before (done)->

		# start a fake FileStore service
		@filestore_host = 'localhost'
		@filestore_port = 9092
		@filestore_app = FakeFileStore()
		@filestore_server = @filestore_app.listen @filestore_port, @filestore_host, (err) =>
			throw err if err?
			console.log ">> test filestore started on #{@filestore_host}:#{@filestore_port}"

		# set up a Previewer test app
		@previewer_host = 'localhost'
		@previewer_port = 9091
		@previewer_app = express()
		@previewer_app.name = 'test_previewer'
		Router(@previewer_app)
		@previewer_server = @previewer_app.listen @previewer_port, @previewer_host, (err) =>
			throw err if err?
			console.log ">> test previewer started on #{@previewer_host}:#{@previewer_port}"
		done()

	after (done) ->
		# shut down both express apps
		@previewer_server.close()
		@filestore_server.close()
		done()

	describe "/status", ->

		it "should respond to status endpoint", (done) ->
			opts = {
				uri: "http://#{@previewer_host}:#{@previewer_port}/status"
				method: 'get'
			}
			request opts, (err, response, body) =>
				expect(response.statusCode).to.equal 200
				expect(body).to.equal "#{@previewer_app.name} is alive"
				done()

	describe "/preview/csv", ->

		it "should get a preview of a good csv file", (done) ->
			file_url = "http://#{@filestore_host}:#{@filestore_port}/file/simple.csv"
			opts = {
				uri: "http://#{@previewer_host}:#{@previewer_port}/preview/csv?fileUrl=#{file_url}"
				method: 'get'
			}
			request opts, (err, response, body) =>
				expect(err).to.equal null
				response.statusCode.should.equal 200
				done()

		it "should produce an error for an unknown file", (done) ->
			file_url = "http://#{@filestore_host}:#{@filestore_port}/file/this_clearly_does_not_exist.csv"
			opts = {
				uri: "http://#{@previewer_host}:#{@previewer_port}/preview/csv?fileUrl=#{file_url}"
				method: 'get'
			}
			request opts, (err, response, body) =>
				expect(err).to.equal null
				response.statusCode.should.equal 404
				done()

		describe "without a fileUrl query param", ->

			it "should produce a 400 response", (done) ->
				opts = {
					uri: "http://#{@previewer_host}:#{@previewer_port}/preview/csv?wat=yes"
					method: 'get'
				}
				request opts, (err, response, body) =>
					expect(err).to.equal null
					response.statusCode.should.equal 400
					done()
