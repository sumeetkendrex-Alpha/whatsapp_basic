import { LightningElement, track,api } from 'lwc';

export default class CurrentLocation extends LightningElement {
    @track latitude;
    @track longitude;
    @track error;
    @track locationRetrieved = false;

    getLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.locationRetrieved = true;
                    this.error = undefined;

                    // Dispatch custom event to parent
                    this.dispatchEvent(new CustomEvent('locationdata', {
                        detail: {
                            latitude: this.latitude,
                            longitude: this.longitude
                        },
                        bubbles: true,
                        composed: true
                    }));
                },
                (error) => {
                    this.error = 'Error retrieving location: ' + error.message;
                    this.locationRetrieved = false;
                }
            );
        } else {
            this.error = 'Geolocation is not supported by this browser.';
        }
    }

    // Public method for parent to call
    @api triggerGetLocation() {
        this.getLocation();
    }
}