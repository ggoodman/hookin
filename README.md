before:change:<field>
--------------

The event will consist of:
* value: The new value being assigned
* oldValue: The former value of the field
* reject(): A callback to reject the change outright and prevent future callbacks.
* change(value): A callback to modify the value sent to future callbacks