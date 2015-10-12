define [
  'backbone'
  './field'
  './select-textarea-input'
  './../templates/field-suggestible'
], (Backbone, FieldView, SelectTextareaInputView, suggestibleFieldTemplate) ->

  # Transcription Grammaticality Field View
  # ---------------------------------------
  #
  # A field view specifically for a grammaticality <select> and a transcription
  # <textarea>. (Compare to the similar utterance-judgement-field view.)
  #
  # The special-purpose logic in this class is for responding to events on the
  # model that communicate suggestions from other fields with respect to the
  # values that the transcription field may want to suggest to the user. At the
  # moment, the morpheme break field can use phonology resources to suggest
  # transcription values based on user morpheme break values.

  class TranscriptionGrammaticalityFieldView extends FieldView

    initialize: (options) ->
      super options

      # When set to `true` this means that the (suggestion) system is
      # responsible for the current value in our <textarea>. When set to
      # `false` (the default), this means that the user is responsible for this
      # value; this prevents our suggestions from overwriting the
      # user-specified input.
      @systemSuggested = false

      # This array will hold a suggestions (strings) for this transcription
      # field.
      @suggestedValues = []

    # Over-write the super-classes `@events` with suggestion-specific listeners.
    events:
      'change':                'setToModel' # fires when multi-select changes
      'selectmenuchange':      'setToModel' # fires when a selectmenu changes
      'menuselect':            'setToModel' # fires when the tags multi-select changes (not working?...)
      'keydown .ms-container': 'multiselectKeydown'
      # New/different from `FieldView` super-class.
      'keydown input, .ui-selectmenu-button, .ms-container':
                               'controlEnterSubmit'
      'keydown textarea':      'myControlEnterSubmit'
      'input':                 'userInput' # fires when an input, textarea or date-picker changes
      'keydown div.suggestion': 'suggestionsKeyboardControl'
      'click .toggle-suggestions': 'toggleSuggestions'
      'click div.suggestion':  'suggestionClicked'
      'mouseover .suggestion': 'hoverStateSuggestionOn'
      'mouseout .suggestion': 'hoverStateSuggestionOff'
      'focusin .suggestion': 'hoverStateSuggestionOn'
      'focusout .suggestion': 'hoverStateSuggestionOff'

    hoverStateSuggestionOn: (event) ->
      @$(event.currentTarget).addClass 'ui-state-hover'

    hoverStateSuggestionOff: (event) ->
      @$(event.currentTarget).removeClass 'ui-state-hover'

    # <Ctrl+Enter> should still submit the form, but now <down arrow> should
    # open the suggestions <div>.
    myControlEnterSubmit: (event) ->
      switch event.which
        when 40
          @stopEvent event
          @openSuggestionsAnimateCheck()
      @controlEnterSubmit event

    template: suggestibleFieldTemplate

    listenToEvents: ->
      super

      # Something is offering us a suggestion for what our transcription value
      # should be.
      @listenTo @model, 'transcription:suggestion', @suggestionReceived

      # The input view's <textarea> has resized itself, so we respond by resizing
      # our .suggestions <div>.
      @listenTo @model, 'textareaWidthResize', @resizeAndPositionSuggestionsDiv

    # The user has entered something into the <textarea>.
    userInput: ->
      @setToModel()
      @systemSuggested = false

    # We have received a suggestion; respond accordingly. This means:
    # 1. potentially inserting the primary suggestion into our <textarea>
    # 2. populating our .suggestions <div> with (a subset of) the suggestions.
    suggestionReceived: (suggestion) ->
      $transcriptionInput = @$('textarea[name=transcription]').first()
      currentValue = $transcriptionInput.val().trim()
      @suggestedValues = @getSuggestedValues suggestion
      if (@systemSuggested or (not currentValue)) and @suggestedValues.length > 0
        @systemSuggested = true
        $transcriptionInput.val @suggestedValues[0]
        @setToModel()
      @addSuggestionsToSuggestionsDiv()

    # Extra GUI niceties for our suggestion machinery.
    guify: ->
      super

      # console.log @constructor.jQueryUIColors()
      # actBa
      # actCo
      # hovBa
      # hovCo

      @$('.suggestions')
        .css "border-color", @constructor.jQueryUIColors().defBo
      @$('button.toggle-suggestions')
        .button()
        .tooltip()
        .hide()
      setTimeout (=> @resizeAndPositionSuggestionsDiv()), 10

    # We set the width of the .suggestions <div> to match that of the
    # <textarea>.
    resizeAndPositionSuggestionsDiv: ->
      $textarea = @$('textarea[name=transcription]').first()
      textareaWidth = $textarea.width()
      margin = if @addUpdateType is 'add' then '34.5%' else '37.5%'
      if textareaWidth
        newWidth = textareaWidth + 20
        @$('.suggestions').first().css
          'width': "#{newWidth}px"
          'margin-left': margin

    # Due to combinatoric explosion, we can get too many suggestions, so we
    # display this many at most.
    maxNoSuggestions: 20

    # Populate our .suggestions <div> with our first `@maxNoSuggestions`
    addSuggestionsToSuggestionsDiv: ->
      if @suggestedValues.length > 0
        @showSuggestionsButtonCheck()
        @$('.suggestions').first().html @getSuggestedValuesHTML()
        # If nothing is currently focused, we take that to mean that the last
        # thing focused was a .suggestion <div> that we just destroyed; so we
        # focus the first new .suggestion <div>.
        if $(':focus').length is 0
          @$('.suggestions').first().find('.suggestion').first().focus()
      else
        @$('.suggestions').html ''
        @hideSuggestionsButtonCheck()

    # Get the HTML for displaying our array of selections (truncated, if
    # needed).
    getSuggestedValuesHTML: ->
      result = []
      for suggestion in @suggestedValues[...@maxNoSuggestions]
        result.push "<div class='suggestion' tabindex='0'>#{suggestion}</div>"
      result.join ''

    # Respond to a 'click' event on a <div.selection> element: put its
    # suggestion text in our <textarea>.
    suggestionClicked: (event) ->
      suggestion = @$(event.currentTarget).text()
      $textarea = @$('textarea[name=transcription]').first()
      $textarea.val suggestion
      @setToModel()
      @$('.suggestions').first().slideUp
        complete: -> $textarea.focus()

    # (Animatedly) toggle the suggestions <div>.
    toggleSuggestions: ->
      $suggestionsDiv = @$('.suggestions').first()
      if $suggestionsDiv.is ':visible'
        $suggestionsDiv.slideUp()
      else
        $suggestionsDiv.slideDown()

    # Open the suggestions <div> (animatedly) and focus the first suggestion.
    openSuggestionsAnimateCheck: ->
      if @suggestedValues.length > 0
        $suggestionsDiv = @$('.suggestions').first()
        if not $suggestionsDiv.is ':visible'
          $suggestionsDiv.slideDown()
        $suggestionsDiv.find('.suggestion').first().focus()

    # Close the suggestions <div> (animatedly) and focus our <textarea>.
    closeSuggestionsAnimate: ->
      @$('.suggestions').first().slideUp()
      @$('textarea[name=transcription]').first().focus()

    # The suggestions <div> has caught a keydown event:
    # - down arrow focuses next suggestion
    # - up arrow focuses previous suggestion (or closes <div> if at top)
    # - <Return> selects focused suggestion (puts it in <textarea>)
    # - <Esc> closes suggestions <div> and focuses textarea
    suggestionsKeyboardControl: (event) ->
      switch event.which
        when 40
          @stopEvent event
          $focused = @$(':focus')
          $next = $focused.next()
          if $next then $next.focus()
        when 38
          @stopEvent event
          $focused = @$(':focus')
          $prev = $focused.prev()
          if $prev.length > 0
            $prev.focus()
          else
            @closeSuggestionsAnimate()
        when 13
          @stopEvent event
          @$(event.currentTarget).click()
        when 27
          @stopEvent event
          @closeSuggestionsAnimate()

    # Show the "toggle suggestions" button if it's not yet visible.
    showSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if not $button.is(':visible') then $button.show()

    # Hide the "toggle suggestions" button (if it is visible).
    hideSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if $button.is(':visible') then $button.hide()

    # Given the suggestor's `suggestion` object, construct an array of
    # suggestions (strings) that we can use. Implicitly, the first element in
    # this array will be interpreted as the primary suggestion.
    # Param `suggestion.suggestion` is an object that maps input strings to
    # arrays of output strings.
    # Param `suggestion.sourceWords` is an array of words defining the source
    # (e.g., the words in the morpheme break value).
    getSuggestedValues: (suggestion) ->
      # `suggestedValuesArray` will be an array of arrays, where the sub-arrays
      # contain the set of string suggestions for each word in the source, in
      # the same order as the source.
      suggestedValuesArray = []
      for word in suggestion.sourceWords
        try
          wordSuggestedValuesArray = suggestion.suggestion[word]
        catch
          # If we have no suggestion, use the input as the output.
          wordSuggestedValuesArray = [word]
        if wordSuggestedValuesArray and
        @utils.type(wordSuggestedValuesArray) is 'array' and
        wordSuggestedValuesArray.length > 0
          suggestedValuesArray.push wordSuggestedValuesArray
        else
          # If our suggestion is not an array with at least one item, use the
          # input as the output.
          suggestedValuesArray.push [word]
      # Since the underlying form of a word can have multiple surface forms,
      # our sentence-level suggestions must contain all possible combinations
      # of surface forms (that match the order of source words, of course).
      @getCombinations suggestedValuesArray

    # Take something like `[['a', 'b'], ['c', 'd', 'e'], ['f']]` and return
    # something like `[ 'a c f', 'a d f', 'a e f', 'b c f', 'b d f', 'b e f']`.
    getCombinations: (suggestedValuesArray) ->
      if suggestedValuesArray.length is 0
        # This should never happen.
        []
      else if suggestedValuesArray.length is 1
        suggestedValuesArray[0]
      else
        result = []
        prefixes = suggestedValuesArray[0]
        suffixes = @getCombinations suggestedValuesArray[1...]
        for prefix in prefixes
          for suffix in suffixes
            result.push "#{prefix} #{suffix}"
        result

    # Override this in a subclass to swap in a new input view, e.g., one based
    # on a <select> or an <input[type=text]>, etc.
    getInputView: ->
      new SelectTextareaInputView @context

    # `FieldView` will call this to set `@context` in the constructor.
    # The `SelectTextareaInputView` instance needs to know how to label/valuate
    # its <select> and <textarea>.
    getContext: ->
      selectAttribute = 'grammaticality'
      selectOptionsAttribute = 'grammaticalities'
      defaultContext = super()
      _.extend(defaultContext,

        selectOptionsAttribute: selectOptionsAttribute
        selectAttribute: selectAttribute
        selectName: @getName selectAttribute
        selectClass: @getClass selectAttribute
        selectTitle: @getTooltip selectAttribute
        selectValue: @getValue selectAttribute

        textareaName: defaultContext.name
        textareaClass: defaultContext.class
        textareaTitle: defaultContext.title
        textareaValue: defaultContext.value
      )

    getValueFromDOM: ->
      value = super
      for k, v of value
        if not v then value[k] = ''
      value

