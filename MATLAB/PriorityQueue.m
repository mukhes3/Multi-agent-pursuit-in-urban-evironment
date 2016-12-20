classdef PriorityQueue < handle
  %PRIORITYQUEUE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    pq
    items
    nItems = 0
  end
  
  methods
    % Constructor
    function obj = PriorityQueue(initSize)
      if nargin == 0
        obj.pq = java.util.PriorityQueue(1);
        obj.items = cell(1,1);
      else
        obj.pq = java.util.PriorityQueue(initSize);
        obj.items = cell(initSize,1);
      end
    end
    
    function bool = add(obj, index, item)
      if item.actionListItemsPos == 0
        if obj.nItems == length(obj.items)
          temp = obj.items;
          obj.items = cell(2*obj.nItems, 1);
          obj.items(1:obj.nItems) = temp;
        end
        obj.nItems = obj.nItems + 1;
        item.actionListItemsPos = obj.nItems;
        obj.items{item.actionListItemsPos} = item;
      end
      bool = obj.pq.add(IndexedItem(index, ...
        item.actionListItemsPos));
    end
    
    function [index, item] = peek(obj)
      ii = obj.pq.peek();
      index = ii.index;
      item = obj.items{ii.item};
    end
    
    function [index, item] = poll(obj)
      ii = obj.pq.poll();
      if isempty(ii) % No items left in queue
        index = [];
        item = [];
      else
        index = ii.index;
        item = obj.items{ii.item};
      end
    end
    
    function len = size(obj)
      len = obj.pq.size();
    end
    
    function clear(obj)
      obj.pq.clear();
    end
    
    function delete(obj)
      obj.pq = [];
      obj.items = [];
    end
  end
  
end

