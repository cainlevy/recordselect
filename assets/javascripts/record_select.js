var RecordSelect = new Object();

RecordSelect.notify = function(item) {
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
}

RecordSelect.Abstract = Class.create();
Object.extend(RecordSelect.Abstract.prototype, {
  /**
   * obj - the id or element that will anchor the recordselect to the page
   * url - the url to run the recordselect
   * options - ??? (check concrete classes)
   */
  initialize: function(obj, url, options) {
    this.obj = $(obj);
    this.url = url;
    this.options = options;
    this.container;

    Event.observe(window, 'load', this.onload.bind(this));
  },

  /**
   * Finish the setup - IE doesn't like doing certain things before the page loads
   * --override--
   */
  onload: function() {},

  /**
   * the onselect event handler - when someone clicks on a record
   * --override--
   */
  onselect: function(id, value) {
    alert(id + ': ' + value);
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
    var offset = Position.cumulativeOffset(this.obj);
    this.container.style.left = offset[0] + 'px';
    this.container.style.top = (Element.getHeight(this.obj) + offset[1]) + 'px';

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
   * when the user clicks outside the dropdown
   */
  onbodyclick: function(ev) {
    if (!this.is_open()) return;
    var elem = $(Event.element(ev));
    var ancestors = elem.ancestors();
    ancestors.push(elem);
    if (ancestors.include(this.container) || ancestors.include(this.obj)) return;
    this.close();
  },

  /**
   * creates and initializes (and returns) the recordselect container
   */
  create_container: function() {
    new Insertion.Bottom(document.body, '<div class="record-select-container record-select-handler"></div>');
    e = document.body.childNodes[document.body.childNodes.length - 1];
    e.onselect = this.onselect.bind(this);
    e.style.display = 'none';

    return $(e);
  }
});

/**
 * Used by link_to_record_select
 * The options hash should contain a onselect: key, with a javascript function as value
 */
RecordSelect.Dialog = Class.create();
RecordSelect.Dialog.prototype = Object.extend(new RecordSelect.Abstract(), {
  onload: function() {
    this.container = this.create_container();
    this.obj.observe('click', this.toggle.bind(this));
  },

  onselect: function(id, value) {
    if (this.options.onselect(id, value) != false) this.close();
  },

  toggle: function() {
    if (this.is_open()) this.close();
    else this.open();
  }
});

/**
 * Used by record_select_field helper
 * The options hash may contain id: and label: keys, designating the current value
 */
RecordSelect.Autocomplete = Class.create();
RecordSelect.Autocomplete.prototype = Object.extend(new RecordSelect.Abstract(), {
  onload: function() {
    // create the hidden input
    new Insertion.After(this.obj, '<input type="hidden" name="" value="" />')
    this.hidden_input = this.obj.next();

    // transfer the input name from the text input to the hidden input
    this.hidden_input.name = this.obj.name;
    this.obj.name = '';

    // initialize the values
    this.set(this.options.id, this.options.label);

    // initialize the container
    this.container = this.create_container();
    this.container.addClassName('record-select-autocomplete');

    // attach the events to start this party
    this.obj.observe('focus', this.open.bind(this));

    // the autosearch event
    this.obj.observe('keyup', function() {
      if (!this.is_open()) return;
      this.container.down('input[name=search]').value = this.obj.value;
    }.bind(this));
  },

  onselect: function(id, value) {
    this.set(id, value);
    this.close();
  },

  /**
   * sets the id/label
   */
  set: function(id, label) {
    this.obj.value = label;
    this.hidden_input.value = id;
  }
});
