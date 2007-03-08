RecordSelect = {
  notify: function (item) {
    var e = item.up('.record-select-handler');
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
    if (obj.next() && Element.hasClassName(obj.next(), 'record-select-container')) return;

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
        Element.observe(window, 'click', function(ev) {
          if (!e || !e.parentNode) return;
          if (Event.element(ev).ancestors().include(e)) return;
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
    if (obj.next() && Element.hasClassName(obj.next(), 'record-select-container')) RecordSelect.close(obj);
    else RecordSelect.open(obj, url, onselect);
  }
}