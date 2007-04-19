var RecordSelect = new Object();

RecordSelect = {
  notify: function (item) {
    var e = Element.up(item, '.record-select-handler');
    var onselect = e.onselect || e.getAttribute('onselect');
    if (typeof onselect != 'function') onselect = eval(onselect);
    if (onselect)
    {
      try {
        onselect(item.parentNode.id.substr(2), item.innerHTML, e);
      } catch(e) {
        alert(e);
      }
      return false;
    }
    else return true;
  },

  open: function(obj, url, onselect) {
    /* don't re-open */
    if (Element.next(obj) && Element.hasClassName(Element.next(obj), 'record-select-container')) return;

    var id = obj.getAttribute('container_id');
    var insertion = new Insertion.Bottom(document.body, '<div class="record-select-container record-select-handler" id="' + id + '"></div>');
    var e = $(id);

    if (Element.hasClassName(obj, 'record-select-autocomplete')) Element.addClassName(e, 'record-select-autocomplete');

    var offset = Position.cumulativeOffset(obj);
    e.style.left = offset[0] + 'px';
    e.style.top = (Element.getHeight(obj) + offset[1]) + 'px';

    e.onselect = onselect;

    new Ajax.Updater(e, url, {
      evalScripts: true,
      asynchronous: true,
      insertion: Insertion.Bottom,
      onSuccess: function() {
        Element.observe(document.body, 'click', function(ev) {
          if (!e || !e.parentNode) return;
          if (Element.ancestors(Event.element(ev)).include(e)) return;
          Element.remove(e);
          delete e;
        });
      }
    });
  },

  close: function(obj) {
    Element.remove($(obj.getAttribute('container_id')));
  },

  toggle: function(obj, url, onselect) {
    if (Element.next(obj) && Element.hasClassName(Element.next(obj), 'record-select-container')) RecordSelect.close(obj);
    else RecordSelect.open(obj, url, onselect);
  }
}






RecordSelect.Autocomplete = Class.create();
Object.extend(RecordSelect.Autocomplete.prototype, {
  /**
   * obj - the text input field
   * url - the url to open the recordselect
   * current - a hash with the current id and label, like {id: '', label: ''}
   */
  initialize: function(obj, url, current) {
    this.text_input = $(obj);
    this.url = url;

    // create the hidden input
    new Insertion.After(this.text_input, '<input type="hidden" name="" value="" />')
    this.hidden_input = this.text_input.next();

    // transfer the input name from the text input to the hidden input
    this.hidden_input.name = this.text_input.name;
    this.text_input.name = '';

    // initialize the values
    this.set(current.id, current.label);

    Event.observe(window, 'load', this.onload.bind(this));
  },

  /**
   * IE doesn't want to do too much until the page has finished loading
   */
  onload: function() {
    // initialize the container
    this.container = this.create_container();

    // attach the events to start this party
    this.text_input.observe('focus', this.open.bind(this));

    // the autosearch event
    this.text_input.observe('keyup', function() {
      if (!this.is_open()) return;
      this.container.down('input[name=search]').value = this.text_input.value;
    }.bind(this));
  },

  /**
   * opens the recordselect
   */
  open: function() {
    if (this.is_open()) return;

    new Ajax.Updater(this.container, this.url, {
      evalScripts: true,
      asynchronous: true,
      insertion: Insertion.Bottom,
      onSuccess: function() {
        this.show();
        Element.observe(document.body, 'click', this.onbodyclick.bindAsEventListener(this));
      }.bind(this)
    });
  },

  /**
   * positions and reveals the recordselect
   */
  show: function() {
    var offset = Position.cumulativeOffset(this.text_input);
    this.container.style.left = offset[0] + 'px';
    this.container.style.top = (Element.getHeight(this.text_input) + offset[1]) + 'px';

    this.container.show();
  },

  /**
   * closes the recordselect by emptying the container
   */
  close: function() {
    this.container.hide();
    // hopefully by using remove() instead of innerHTML we won't leak memory
    this.container.immediateDescendants().invoke('remove');
  },

  /**
   * returns true/false for whether the recordselect is open
   */
  is_open: function() {
    return (this.container.childNodes.length > 0)
  },

  /**
   * the onselect event handler - when someone clicks on a record
   */
  onselect: function(id, value) {
    this.set(id, value);
    this.close();
  },

  /**
   * when the user clicks outside the dropdown
   */
  onbodyclick: function(ev) {
    if (!this.is_open()) return;
    var elem = $(Event.element(ev));
    var ancestors = elem.ancestors();
    ancestors.push(elem);
    if (ancestors.include(this.container) || ancestors.include(this.text_input)) return;
    this.close();
  },

  /**
   * sets the id/label
   */
  set: function(id, label) {
    this.text_input.value = label;
    this.hidden_input.value = id;
  },

  /**
   * creates and initializes (and returns) the recordselect container
   */
  create_container: function() {
    new Insertion.Bottom(document.body, '<div class="record-select-container record-select-handler record-select-autocomplete"></div>');
    e = document.body.childNodes[document.body.childNodes.length - 1];
    e.onselect = this.onselect.bind(this);
    e.style.display = 'none';

    return $(e);
  }
});
