# Deps
scrollMonitor = require 'scrollmonitor'

# Mixin definition
module.exports =

	# Public interface
	props:

		# Add listeners and check if in viewport immediately
		inViewportActive:
			type: Boolean
			default: true

		# Only update once by default. The assumption is that it will be used for
		# one-time buildins
		inViewportOnce:
			type: Boolean
			default: false

		# Shared offsets
		inViewportOffset:
			type: Number
			default: 0
		inViewportOffsetTop:
			type: Number
			default: null
		inViewportOffsetBottom:
			type: Number
			default: null

	# Bindings that are used by the host component
	data: -> inViewport:

		# Public props
		scrollMonitor: null # scrollMonitor
		now: null   # Is in viewport
		fully: null # Is fully in viewport
		above: null # Is partially or fully above the viewport
		below: null # Is partially or fully below the viewport

		# Internal props
		listening: false

	# Use general offset if none are defined
	computed:
		inViewportOffsetTopComputed: -> @inViewportOffsetTop ? @inViewportOffset
		inViewportOffsetBottomComputed: -> @inViewportOffsetBottom ? @inViewportOffset
		inViewportOffsetComputed: ->
			top: @inViewportOffsetTopComputed
			bottom: @inViewportOffsetBottomComputed

	# Lifecycle hooks
	mounted: -> @$nextTick(@inViewportInit)
	destroyed: -> @removeInViewportHandlers()

	# Watch props and data
	watch:

		# Add or remove event handlers handlers
		inViewportActive: (active) ->
			if active
			then @addInViewportHandlers()
			else @removeInViewportHandlers()

		# If the offsets change, need to rebuild scrollMonitor instance because it
		# doesn't offer an API to update the offset
		inViewportOffsetComputed:
			deep: true
			handler: ->
				@removeInViewportHandlers()
				@inViewportInit()

	# Public API
	methods:

		# Instantiate
		inViewportInit: -> @addInViewportHandlers() if @inViewportActive

		# Add listeners
		addInViewportHandlers: ->

			# Don't add twice
			return if @inViewport.listening
			@inViewport.listening = true

			# Create scrollMonitor instance which starts watching scroll
			@scrollMonitor = scrollMonitor
			@scrollMonitorWatcher = scrollMonitor.create @$el, @inViewportOffsetComputed

			# Start listening for changes
			@scrollMonitorWatcher.on 'stateChange', @updateInViewport

			# Update intiial state, which also handles `once` prop
			@updateInViewport()

		# Remove listeners
		removeInViewportHandlers: ->

			# Don't remove twice
			return unless @inViewport.listening
			@inViewport.listening = false

			# Destroy instance, which also removes listeners
			@scrollMonitorWatcher.destroy() if @scrollMonitorWatcher
			delete @scrollMonitorWatcher

		# Handle state changes from scrollMonitor
		updateInViewport: ->

			# Update state values
			@inViewport.now   = @scrollMonitorWatcher.isInViewport
			@inViewport.fully = @scrollMonitorWatcher.isFullyInViewport
			@inViewport.above = @scrollMonitorWatcher.isAboveViewport
			@inViewport.below = @scrollMonitorWatcher.isBelowViewport

			# If set to update "once", remove listeners if in viewport
			@removeInViewportHandlers() if @inViewportOnce and @inViewport.now
