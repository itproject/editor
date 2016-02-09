_ = require 'lodash'
Parser = new DOMParser()
require('string_score')

module.exports =
class HTMLAnalizer
  constructor: (content, @event) ->
    @dom = $(Parser.parseFromString(content, 'text/html'))
    @selector_parts = @event.selector.split(' > ')

  analize: ->
    strongest_combination = @strongestCombination()
    return { score: 0 } unless strongest_combination

    strongest_combination

  strongestCombination: ->
    all_combinations = @allCombinations()
    return unless all_combinations.length

    scored_combinations = _.map all_combinations, (combination) =>
      combination.type = 'html'
      combination.dom = @dom
      combination.string_score = @stringScore(combination)
      combination.text = combination.element.innerText
      combination.score = combination.string_score * 0.8 + combination.selector_score * 0.2
      combination

    _.maxBy scored_combinations, 'score'

  stringScore: (combination) ->
    max_selector_scale = 12
    _.trim(@event.inner_text).score(_.trim(combination.element.innerText)) * max_selector_scale

  allCombinations: ->
    result = []
    NTH_CHILD_REGEX = /:nth\-child\(\d\)/

    _.times @selector_parts.length + 1, (i) =>
      selector = _.takeRight(@selector_parts, i).join(' > ')
      element = @dom.find(selector)[0]
      return true unless element

      result.push
        selector: selector
        selector_score: i
        element: element

    bare_selector = _.last(@selector_parts).replace(NTH_CHILD_REGEX, '')
    _.each @dom.find(bare_selector), (element) ->
      result.push
        selector: bare_selector
        selector_score: 0.1
        element: element

    result