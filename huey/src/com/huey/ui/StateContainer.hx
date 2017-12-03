package com.huey.ui;

/**
 * ...
 * @author Newgrounds.com, Inc.
 */

class StateContainer extends Container {
	public var state(default, setState) : String;
	private function setState(v : String) : String {
		var oldState = _states.get(state);
		if (oldState != null) {
			for(child in oldState)
				remove(child);
		}
		
		var newState = _states.get(v);
		if (newState != null) {
			for (comp in newState) add(comp);
		}

		return state = v;
	}
	
	
	private var _states : Hash<UIState>;
	
	public function addToState(component : Component, state : String) : Void {
		if (!_states.exists(state)) _states.set(state, new UIState());
		_states.get(state).push(component);
		if (this.state == null) this.state = state;
		else if (state == this.state) add(component);
	}

	public function new() {
		super();
		_states = new Hash();
	}
}

typedef UIState = Array<Component>;