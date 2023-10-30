# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""Data class Models"""

from pydantic import BaseModel


class TelemetryModel(BaseModel):
    """Experiment Telemetry model"""

    branch: str
    experiment: str
